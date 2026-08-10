import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../database/database.service';
import { VerificationHistoryService } from './verification.history.service';
import { VerificationService } from './verification.service';

describe('VerificationService', () => {
  let service: VerificationService;

  const database = {
    post: {
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    witness: {
      count: jest.fn(),
    },
  };

  const config = {
    get: jest.fn(),
  };

  const verificationHistory = {
    recordStatusChanged: jest.fn(),
  };

  const postStatus = (status: string) => ({
    id: 'post-1',
    verificationStatus: status,
  });

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VerificationService,
        {
          provide: DatabaseService,
          useValue: database,
        },
        {
          provide: ConfigService,
          useValue: config,
        },
        {
          provide: VerificationHistoryService,
          useValue: verificationHistory,
        },
      ],
    }).compile();

    service = module.get(VerificationService);

    config.get.mockReturnValue(undefined);
    database.witness.count.mockResolvedValue(0);
    verificationHistory.recordStatusChanged.mockResolvedValue(undefined);
  });

  it('is defined', () => {
    expect(service).toBeDefined();
  });

  it('reports a new post as REPORTED with no witnesses', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(0);

    await expect(service.getVerificationStatus('post-1')).resolves.toEqual({
      status: 'REPORTED',
      witnessCount: 0,
    });
  });

  it('moves REPORTED to UNDER_VERIFICATION on the first witness', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(1);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'UNDER_VERIFICATION',
      witnessCount: 1,
    });

    expect(database.post.update).toHaveBeenCalledWith({
      where: { id: 'post-1' },
      data: { verificationStatus: 'UNDER_VERIFICATION' },
    });
  });

  it('records a STATUS_CHANGED event and STATUS_TRANSITION contribution on transition', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(1);

    await service.evaluatePost('post-1');

    expect(verificationHistory.recordStatusChanged).toHaveBeenCalledWith(
      'post-1',
      'REPORTED',
      'UNDER_VERIFICATION',
      undefined,
    );
  });

  it('records nothing when the status does not change', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('UNDER_VERIFICATION'));
    database.witness.count.mockResolvedValue(1);

    await service.evaluatePost('post-1');

    expect(database.post.update).not.toHaveBeenCalled();
    expect(verificationHistory.recordStatusChanged).not.toHaveBeenCalled();
  });

  it('forwards the transaction client when evaluating inside one', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(1);

    const tx = {
      post: {
        findFirst: jest.fn().mockResolvedValue(postStatus('REPORTED')),
        update: jest.fn().mockResolvedValue({}),
      },
      witness: {
        count: jest.fn().mockResolvedValue(1),
      },
    };

    await service.evaluatePost('post-1', tx as never);

    expect(tx.post.findFirst).toHaveBeenCalled();
    expect(tx.witness.count).toHaveBeenCalled();
    expect(tx.post.update).toHaveBeenCalledWith({
      where: { id: 'post-1' },
      data: { verificationStatus: 'UNDER_VERIFICATION' },
    });
    expect(verificationHistory.recordStatusChanged).toHaveBeenCalledWith(
      'post-1',
      'REPORTED',
      'UNDER_VERIFICATION',
      tx,
    );
    expect(database.post.findFirst).not.toHaveBeenCalled();
    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('moves UNDER_VERIFICATION to LOCALLY_VERIFIED at the threshold', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('UNDER_VERIFICATION'));
    database.witness.count.mockResolvedValue(2);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 2,
    });

    expect(database.post.update).toHaveBeenCalledWith({
      where: { id: 'post-1' },
      data: { verificationStatus: 'LOCALLY_VERIFIED' },
    });
  });

  it('uses the configured local verification threshold', async () => {
    config.get.mockReturnValue('3');
    database.post.findFirst.mockResolvedValue(postStatus('UNDER_VERIFICATION'));
    database.witness.count.mockResolvedValue(3);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 3,
    });

    expect(database.post.update).toHaveBeenCalledWith({
      where: { id: 'post-1' },
      data: { verificationStatus: 'LOCALLY_VERIFIED' },
    });
  });

  it('falls back to the default threshold when configuration is invalid', async () => {
    config.get.mockReturnValue('not-a-number');
    database.post.findFirst.mockResolvedValue(postStatus('UNDER_VERIFICATION'));
    database.witness.count.mockResolvedValue(2);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 2,
    });
  });

  it('duplicate witnesses do not inflate the count beyond unique records', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(1);

    await service.evaluatePost('post-1');
    await service.evaluatePost('post-1');

    expect(database.witness.count).toHaveBeenCalledTimes(2);
    expect(database.post.update).toHaveBeenNthCalledWith(1, {
      where: { id: 'post-1' },
      data: { verificationStatus: 'UNDER_VERIFICATION' },
    });
  });

  it('does not auto-count the author: zero witnesses leaves REPORTED', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));
    database.witness.count.mockResolvedValue(0);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'REPORTED',
      witnessCount: 0,
    });

    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('never downgrades LOCALLY_VERIFIED when witnesses are removed', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('LOCALLY_VERIFIED'));
    database.witness.count.mockResolvedValue(1);

    await expect(service.getVerificationStatus('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 1,
    });

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 1,
    });

    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('keeps UNDER_VERIFICATION below the threshold without forced promotion', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('UNDER_VERIFICATION'));
    database.witness.count.mockResolvedValue(1);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'UNDER_VERIFICATION',
      witnessCount: 1,
    });

    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('passes through an unknown/future stored status without mutating', async () => {
    database.post.findFirst.mockResolvedValue(
      postStatus('AUTHORITY_CONFIRMED'),
    );
    database.witness.count.mockResolvedValue(5);

    await expect(service.evaluatePost('post-1')).resolves.toEqual({
      status: 'AUTHORITY_CONFIRMED',
      witnessCount: 5,
    });

    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('rejects a missing post with 404', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(service.getVerificationStatus('missing')).rejects.toThrow(
      NotFoundException,
    );

    await expect(service.evaluatePost('missing')).rejects.toThrow(
      NotFoundException,
    );

    expect(database.witness.count).not.toHaveBeenCalled();
  });

  it('rejects a deleted post with 404', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(service.getVerificationStatus('deleted-post')).rejects.toThrow(
      NotFoundException,
    );

    await expect(service.evaluatePost('deleted-post')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('reads only active posts before evaluating', async () => {
    database.post.findFirst.mockResolvedValue(postStatus('REPORTED'));

    await service.evaluatePost('post-1');

    expect(database.post.findFirst).toHaveBeenCalledWith({
      where: {
        id: 'post-1',
        deletedAt: null,
      },
      select: {
        id: true,
        verificationStatus: true,
      },
    });
  });
});
