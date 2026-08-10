import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { VerificationHistoryService } from './verification.history.service';
import { VerificationService } from './verification.service';
import { WitnessService } from './witness.service';

describe('WitnessService', () => {
  let service: WitnessService;

  const transactionClient = {
    post: {
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    witness: {
      findUnique: jest.fn(),
      create: jest.fn(),
      deleteMany: jest.fn(),
      count: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  const database = {
    post: {
      findFirst: jest.fn(),
    },
    witness: {
      count: jest.fn(),
      findFirst: jest.fn(),
    },
    $transaction: jest.fn((callback: (tx: any) => Promise<unknown>) =>
      callback(transactionClient),
    ),
  };

  const verificationService = {
    evaluatePost: jest.fn(),
    getVerificationStatus: jest.fn(),
  };

  const verificationHistory = {
    recordWitnessAdded: jest.fn(),
    recordWitnessRemoved: jest.fn(),
    recordWitnessContribution: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WitnessService,
        {
          provide: DatabaseService,
          useValue: database,
        },
        {
          provide: VerificationService,
          useValue: verificationService,
        },
        {
          provide: VerificationHistoryService,
          useValue: verificationHistory,
        },
      ],
    }).compile();

    service = module.get(WitnessService);

    database.post.findFirst.mockResolvedValue({
      id: 'post-1',
    });

    transactionClient.witness.findUnique.mockResolvedValue(null);
    transactionClient.witness.create.mockResolvedValue({
      id: 'witness-1',
    });
    transactionClient.witness.deleteMany.mockResolvedValue({ count: 1 });
    transactionClient.witness.count.mockResolvedValue(1);
    transactionClient.witness.findFirst.mockResolvedValue({
      id: 'witness-1',
    });

    database.witness.count.mockResolvedValue(1);
    database.witness.findFirst.mockResolvedValue({
      id: 'witness-1',
    });

    verificationService.evaluatePost.mockResolvedValue({
      status: 'UNDER_VERIFICATION',
      witnessCount: 1,
    });

    verificationService.getVerificationStatus.mockResolvedValue({
      status: 'REPORTED',
      witnessCount: 1,
    });
  });

  it('is defined', () => {
    expect(service).toBeDefined();
  });

  it('witnesses a post and returns metadata plus verification', async () => {
    await expect(service.witness('user-1', 'post-1')).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: true,
      verification: {
        status: 'UNDER_VERIFICATION',
        witnessCount: 1,
      },
    });

    expect(transactionClient.witness.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-1',
        postId: 'post-1',
      },
    });
  });

  it('records a WITNESS_ADDED event and WITNESS contribution for a new witness', async () => {
    await service.witness('user-1', 'post-1');

    expect(transactionClient.witness.findUnique).toHaveBeenCalledWith({
      where: {
        userId_postId: {
          userId: 'user-1',
          postId: 'post-1',
        },
      },
      select: {
        id: true,
      },
    });
    expect(verificationHistory.recordWitnessAdded).toHaveBeenCalledWith(
      'post-1',
      transactionClient,
    );
    expect(verificationHistory.recordWitnessContribution).toHaveBeenCalledWith(
      'post-1',
      transactionClient,
    );
    expect(transactionClient.witness.create).toHaveBeenCalledTimes(1);
  });

  it('evaluates verification state inside the same transaction after saving a witness', async () => {
    await service.witness('user-1', 'post-1');

    expect(database.$transaction).toHaveBeenCalledTimes(1);
    expect(transactionClient.witness.create).toHaveBeenCalledTimes(1);
    expect(verificationService.evaluatePost).toHaveBeenCalledWith(
      'post-1',
      transactionClient,
    );
  });

  it('reports LOCALLY_VERIFIED once the second unique witness reaches the threshold', async () => {
    verificationService.evaluatePost.mockResolvedValue({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 2,
    });
    transactionClient.witness.count.mockResolvedValue(2);

    await expect(service.witness('user-2', 'post-1')).resolves.toEqual({
      witnessCount: 2,
      witnessedByMe: true,
      verification: {
        status: 'LOCALLY_VERIFIED',
        witnessCount: 2,
      },
    });
  });

  it('records no event or contribution for a duplicate witness', async () => {
    transactionClient.witness.findUnique.mockResolvedValue({
      id: 'witness-1',
    });

    await service.witness('user-1', 'post-1');

    expect(transactionClient.witness.create).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessAdded).not.toHaveBeenCalled();
    expect(
      verificationHistory.recordWitnessContribution,
    ).not.toHaveBeenCalled();
    expect(verificationService.evaluatePost).toHaveBeenCalledTimes(1);
  });

  it('wraps witness create, events, contribution, and evaluation in one transaction', async () => {
    await service.witness('user-1', 'post-1');

    const callback = database.$transaction.mock.calls[0][0];
    const tx = transactionClient;
    tx.witness.findUnique.mockClear();
    tx.witness.create.mockClear();
    verificationHistory.recordWitnessAdded.mockClear();
    verificationHistory.recordWitnessContribution.mockClear();

    await callback(tx);

    expect(tx.witness.findUnique).toHaveBeenCalled();
    expect(tx.witness.create).toHaveBeenCalled();
    expect(verificationHistory.recordWitnessAdded).toHaveBeenCalled();
    expect(verificationHistory.recordWitnessContribution).toHaveBeenCalled();
  });

  it('unwitnesses safely, including an already-unwitnessed post', async () => {
    transactionClient.witness.deleteMany.mockResolvedValue({ count: 0 });
    transactionClient.witness.count.mockResolvedValue(0);
    transactionClient.witness.findFirst.mockResolvedValue(null);

    await expect(service.unwitness('user-1', 'post-1')).resolves.toEqual({
      witnessCount: 0,
      witnessedByMe: false,
      verification: {
        status: 'REPORTED',
        witnessCount: 1,
      },
    });

    expect(transactionClient.witness.deleteMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        postId: 'post-1',
      },
    });

    expect(verificationHistory.recordWitnessRemoved).not.toHaveBeenCalled();
    expect(
      verificationHistory.recordWitnessContribution,
    ).not.toHaveBeenCalled();
    expect(verificationService.evaluatePost).not.toHaveBeenCalled();
  });

  it('records a WITNESS_REMOVED event only when a witness was actually removed', async () => {
    await service.unwitness('user-1', 'post-1');

    expect(verificationHistory.recordWitnessRemoved).toHaveBeenCalledWith(
      'post-1',
      transactionClient,
    );
  });

  it('does not downgrade LOCALLY_VERIFIED after unwitness', async () => {
    verificationService.getVerificationStatus.mockResolvedValue({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 1,
    });

    await expect(service.unwitness('user-1', 'post-1')).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: true,
      verification: {
        status: 'LOCALLY_VERIFIED',
        witnessCount: 1,
      },
    });

    expect(verificationService.getVerificationStatus).toHaveBeenCalledWith(
      'post-1',
      transactionClient,
    );
  });

  it('rejects witnessing a missing or deleted post', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(service.witness('user-1', 'missing')).rejects.toThrow(
      NotFoundException,
    );

    await expect(service.unwitness('user-1', 'missing')).rejects.toThrow(
      NotFoundException,
    );

    expect(database.$transaction).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessAdded).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessRemoved).not.toHaveBeenCalled();
    expect(verificationService.evaluatePost).not.toHaveBeenCalled();
  });

  it('returns count and current-user state without exposing witness rows', async () => {
    database.witness.count.mockResolvedValue(2);
    database.witness.findFirst.mockResolvedValue(null);

    await expect(service.getStatus('user-2', 'post-1')).resolves.toEqual({
      witnessCount: 2,
      witnessedByMe: false,
      verification: {
        status: 'REPORTED',
        witnessCount: 1,
      },
    });
  });

  it('checks only active posts before returning witness status', async () => {
    await service.getStatus('user-1', 'post-1');

    expect(database.post.findFirst).toHaveBeenCalledWith({
      where: {
        id: 'post-1',
        deletedAt: null,
      },
      select: {
        id: true,
      },
    });
  });

  it('rejects witnessing a soft-deleted post', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(service.witness('user-1', 'deleted-post')).rejects.toThrow(
      NotFoundException,
    );

    await expect(service.unwitness('user-1', 'deleted-post')).rejects.toThrow(
      NotFoundException,
    );

    await expect(service.getStatus('user-1', 'deleted-post')).rejects.toThrow(
      NotFoundException,
    );

    expect(database.$transaction).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessAdded).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessRemoved).not.toHaveBeenCalled();
    expect(verificationService.evaluatePost).not.toHaveBeenCalled();
    expect(verificationService.getVerificationStatus).not.toHaveBeenCalled();
  });

  it('keeps witness state isolated per user', async () => {
    transactionClient.witness.count.mockResolvedValue(1);
    transactionClient.witness.findFirst.mockResolvedValue({ id: 'witness-1' });

    await expect(service.getStatus('user-1', 'post-1')).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: true,
      verification: {
        status: 'REPORTED',
        witnessCount: 1,
      },
    });

    database.witness.findFirst.mockResolvedValue(null);

    await expect(service.getStatus('user-2', 'post-1')).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: false,
      verification: {
        status: 'REPORTED',
        witnessCount: 1,
      },
    });
  });

  it('never records history for a plain status read', async () => {
    await service.getStatus('user-1', 'post-1');

    expect(verificationHistory.recordWitnessAdded).not.toHaveBeenCalled();
    expect(verificationHistory.recordWitnessRemoved).not.toHaveBeenCalled();
    expect(
      verificationHistory.recordWitnessContribution,
    ).not.toHaveBeenCalled();
  });
});
