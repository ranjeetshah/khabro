import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { VerificationHistoryService } from './verification.history.service';

describe('VerificationHistoryService', () => {
  let service: VerificationHistoryService;

  const transactionClient = {
    verificationEvent: {
      create: jest.fn(),
    },
    verificationContribution: {
      create: jest.fn(),
    },
  };

  const database = {
    post: {
      findFirst: jest.fn(),
    },
    verificationEvent: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    verificationContribution: {
      create: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const event = (overrides: Record<string, unknown> = {}) => ({
    id: 'event-1',
    postId: 'post-1',
    type: 'WITNESS_ADDED',
    fromStatus: null,
    toStatus: null,
    createdAt: new Date('2026-08-10T00:00:00.000Z'),
    ...overrides,
  });

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VerificationHistoryService,
        {
          provide: DatabaseService,
          useValue: database,
        },
      ],
    }).compile();

    service = module.get(VerificationHistoryService);

    database.post.findFirst.mockResolvedValue({ id: 'post-1' });
    database.verificationEvent.create.mockResolvedValue({ id: 'event-1' });
    database.verificationContribution.create.mockResolvedValue({
      id: 'contribution-1',
    });
    database.$transaction.mockImplementation(() => Promise.resolve([]));
  });

  it('is defined', () => {
    expect(service).toBeDefined();
  });

  describe('VerificationEvent recording', () => {
    it('records POST_CREATED with toStatus REPORTED', async () => {
      await service.recordPostCreated('post-1');

      expect(database.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'POST_CREATED',
          toStatus: 'REPORTED',
        },
      });
    });

    it('records WITNESS_ADDED', async () => {
      await service.recordWitnessAdded('post-1');

      expect(database.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'WITNESS_ADDED',
        },
      });
    });

    it('records WITNESS_REMOVED', async () => {
      await service.recordWitnessRemoved('post-1');

      expect(database.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'WITNESS_REMOVED',
        },
      });
    });

    it('records STATUS_CHANGED with fromStatus and toStatus', async () => {
      await service.recordStatusChanged(
        'post-1',
        'REPORTED',
        'UNDER_VERIFICATION',
      );

      expect(database.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'STATUS_CHANGED',
          fromStatus: 'REPORTED',
          toStatus: 'UNDER_VERIFICATION',
        },
      });
    });

    it('routes POST_CREATED through the transaction client when provided', async () => {
      await service.recordPostCreated('post-1', transactionClient as never);

      expect(transactionClient.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'POST_CREATED',
          toStatus: 'REPORTED',
        },
      });
      expect(database.verificationEvent.create).not.toHaveBeenCalled();
    });

    it('routes STATUS_CHANGED through the transaction client when provided', async () => {
      await service.recordStatusChanged(
        'post-1',
        'UNDER_VERIFICATION',
        'LOCALLY_VERIFIED',
        transactionClient as never,
      );

      expect(transactionClient.verificationEvent.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'STATUS_CHANGED',
          fromStatus: 'UNDER_VERIFICATION',
          toStatus: 'LOCALLY_VERIFIED',
        },
      });
      expect(
        transactionClient.verificationContribution.create,
      ).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'STATUS_TRANSITION',
        },
      });
      expect(database.$transaction).not.toHaveBeenCalled();
    });

    it('is atomic when recording STATUS_CHANGED without an outer transaction', async () => {
      database.verificationEvent.create.mockReturnValue('event-promise');
      database.verificationContribution.create.mockReturnValue(
        'contribution-promise',
      );

      await service.recordStatusChanged(
        'post-1',
        'REPORTED',
        'UNDER_VERIFICATION',
      );

      expect(database.$transaction).toHaveBeenCalledWith([
        'event-promise',
        'contribution-promise',
      ]);
    });
  });

  describe('getHistory', () => {
    it('returns events oldest-first by createdAt then id', async () => {
      database.verificationEvent.findMany.mockResolvedValue([
        event({
          id: 'event-1',
          createdAt: new Date('2026-08-10T00:00:00.000Z'),
        }),
        event({
          id: 'event-2',
          createdAt: new Date('2026-08-10T00:00:01.000Z'),
        }),
      ]);

      const result = await service.getHistory('post-1');

      expect(database.verificationEvent.findMany).toHaveBeenCalledWith({
        where: { postId: 'post-1' },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        select: {
          type: true,
          fromStatus: true,
          toStatus: true,
          createdAt: true,
        },
      });

      expect(result.events).toHaveLength(2);
      expect(result.events[0]).toEqual({
        type: 'WITNESS_ADDED',
        createdAt: new Date('2026-08-10T00:00:00.000Z'),
      });
      expect(result.events[1]).toEqual({
        type: 'WITNESS_ADDED',
        createdAt: new Date('2026-08-10T00:00:01.000Z'),
      });
      expect(result.events[0].id).toBeUndefined();
    });

    it('exposes only safe metadata, never internal rows', async () => {
      database.verificationEvent.findMany.mockResolvedValue([
        event({
          id: 'event-1',
          postId: 'post-1',
          type: 'STATUS_CHANGED',
          fromStatus: 'REPORTED',
          toStatus: 'UNDER_VERIFICATION',
          createdAt: new Date('2026-08-10T00:00:00.000Z'),
        }),
      ]);

      const result = await service.getHistory('post-1');

      expect(result.events[0]).toEqual({
        type: 'STATUS_CHANGED',
        fromStatus: 'REPORTED',
        toStatus: 'UNDER_VERIFICATION',
        createdAt: new Date('2026-08-10T00:00:00.000Z'),
      });
    });

    it('omits null status fields and leaves unrelated fields optional', async () => {
      database.verificationEvent.findMany.mockResolvedValue([
        event({ type: 'POST_CREATED', toStatus: 'REPORTED' }),
        event({ type: 'WITNESS_ADDED' }),
      ]);

      const result = await service.getHistory('post-1');

      expect(result.events[0]).toEqual({
        type: 'POST_CREATED',
        toStatus: 'REPORTED',
        createdAt: result.events[0].createdAt,
      });
      expect(Object.keys(result.events[0])).toEqual(
        expect.arrayContaining(['type', 'createdAt']),
      );
      expect(result.events[0].fromStatus).toBeUndefined();

      expect(result.events[1]).toEqual({
        type: 'WITNESS_ADDED',
        createdAt: result.events[1].createdAt,
      });
      expect(result.events[1].fromStatus).toBeUndefined();
      expect(result.events[1].toStatus).toBeUndefined();
    });

    it('returns an empty events list when no events exist', async () => {
      database.verificationEvent.findMany.mockResolvedValue([]);

      await expect(service.getHistory('post-1')).resolves.toEqual({
        events: [],
      });
    });

    it('rejects a missing post with 404', async () => {
      database.post.findFirst.mockResolvedValue(null);

      await expect(service.getHistory('missing')).rejects.toThrow(
        NotFoundException,
      );

      expect(database.verificationEvent.findMany).not.toHaveBeenCalled();
    });

    it('rejects a soft-deleted post with 404', async () => {
      database.post.findFirst.mockResolvedValue(null);

      await expect(service.getHistory('deleted-post')).rejects.toThrow(
        NotFoundException,
      );

      expect(database.verificationEvent.findMany).not.toHaveBeenCalled();
    });

    it('checks only active posts before reading history', async () => {
      await service.getHistory('post-1');

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
  });

  describe('VerificationContribution recording', () => {
    it('records a WITNESS contribution', async () => {
      await service.recordWitnessContribution('post-1');

      expect(database.verificationContribution.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'WITNESS',
        },
      });
    });

    it('records a STATUS_TRANSITION contribution', async () => {
      await service.recordStatusChanged(
        'post-1',
        'REPORTED',
        'UNDER_VERIFICATION',
      );

      expect(database.verificationContribution.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'STATUS_TRANSITION',
        },
      });
    });

    it('routes WITNESS contributions through the transaction client when provided', async () => {
      await service.recordWitnessContribution(
        'post-1',
        transactionClient as never,
      );

      expect(
        transactionClient.verificationContribution.create,
      ).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          type: 'WITNESS',
        },
      });
      expect(database.verificationContribution.create).not.toHaveBeenCalled();
    });

    it('never records contributions for reads or status reads', async () => {
      await service.getHistory('post-1');

      expect(database.verificationContribution.create).not.toHaveBeenCalled();
      expect(
        transactionClient.verificationContribution.create,
      ).not.toHaveBeenCalled();
    });

    it('never records contributions when only an event is recorded', async () => {
      await service.recordWitnessAdded('post-1');
      await service.recordWitnessRemoved('post-1');
      await service.recordPostCreated('post-1');

      expect(database.verificationContribution.create).not.toHaveBeenCalled();
    });

    it('records exactly one contribution per witness add and per transition', async () => {
      await service.recordWitnessContribution('post-1');
      await service.recordWitnessContribution('post-1');
      await service.recordStatusChanged(
        'post-1',
        'REPORTED',
        'UNDER_VERIFICATION',
      );

      expect(database.verificationContribution.create).toHaveBeenCalledTimes(3);
      expect(database.verificationContribution.create).toHaveBeenNthCalledWith(
        3,
        {
          data: {
            postId: 'post-1',
            type: 'STATUS_TRANSITION',
          },
        },
      );
    });
  });
});
