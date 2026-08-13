import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { FeedbackService } from './feedback.service';
import { FeedbackStatus, FeedbackType, ModerationAuditAction } from '../generated/prisma/enums';

describe('FeedbackService', () => {
  let service: FeedbackService;

  const database = {
    feedback: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    moderationAuditEvent: {
      create: jest.fn(),
    },
    $transaction: jest.fn((callback: (tx: any) => Promise<unknown>) =>
      callback(database),
    ),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FeedbackService,
        { provide: DatabaseService, useValue: database },
      ],
    }).compile();
    service = module.get(FeedbackService);
  });

  it('is defined', () => expect(service).toBeDefined());

  describe('create', () => {
    it('creates feedback for authenticated user', async () => {
      database.feedback.create.mockResolvedValue({
        id: 'f-1',
        type: FeedbackType.BUG,
        message: 'Bug here',
        status: FeedbackStatus.OPEN,
        createdAt: new Date(),
        appVersion: '1.0.0',
        platform: 'android',
      });

      const result = await service.create('user-1', {
        type: FeedbackType.BUG,
        message: 'Bug here',
        appVersion: '1.0.0',
        platform: 'android',
      });

      expect(result).toEqual({
        id: 'f-1',
        type: FeedbackType.BUG,
        message: 'Bug here',
        status: FeedbackStatus.OPEN,
        createdAt: expect.any(Date),
        appVersion: '1.0.0',
        platform: 'android',
      });
      expect(database.feedback.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          type: FeedbackType.BUG,
          message: 'Bug here',
          appVersion: '1.0.0',
          platform: 'android',
        },
        select: expect.any(Object),
      });
    });

    it('trims message and stores null for empty optional fields', async () => {
      database.feedback.create.mockResolvedValue({
        id: 'f-2',
        type: FeedbackType.FEEDBACK,
        message: 'Trimmed',
        status: FeedbackStatus.OPEN,
        createdAt: new Date(),
      });

      await service.create('user-1', {
        type: FeedbackType.FEEDBACK,
        message: '  Trimmed  ',
      });

      expect(database.feedback.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            message: 'Trimmed',
            appVersion: null,
            platform: null,
          }),
        }),
      );
    });
  });

  describe('getMyFeedback', () => {
    it('returns paginated feedback for the user', async () => {
      database.feedback.findMany.mockResolvedValue([
        {
          id: 'f-1',
          type: FeedbackType.BUG,
          message: 'Bug',
          status: FeedbackStatus.OPEN,
          createdAt: new Date('2026-08-13T00:00:00Z'),
        },
      ]);
      database.feedback.count.mockResolvedValue(1);

      const result = await service.getMyFeedback('user-1', 1, 20);

      expect(result.items).toHaveLength(1);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
      expect(result.total).toBe(1);
      expect(result.hasMore).toBe(false);
      expect(database.feedback.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId: 'user-1' },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        }),
      );
    });

    it('enforces bounded pagination', async () => {
      database.feedback.findMany.mockResolvedValue([]);
      database.feedback.count.mockResolvedValue(0);

      await service.getMyFeedback('user-1', 0, 100);

      expect(database.feedback.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          skip: 0,
          take: 50,
        }),
      );
    });
  });

  describe('getFeedbacks', () => {
    it('returns paginated feedback list for moderators', async () => {
      database.feedback.findMany.mockResolvedValue([
        {
          id: 'f-1',
          type: FeedbackType.BUG,
          message: 'Bug',
          status: FeedbackStatus.OPEN,
          createdAt: new Date('2026-08-13T00:00:00Z'),
          appVersion: '1.0.0',
          platform: 'android',
          user: { id: 'user-1', name: 'User A' },
        },
      ]);
      database.feedback.count.mockResolvedValue(1);

      const result = await service.getFeedbacks({
        page: 1,
        limit: 10,
        type: FeedbackType.BUG,
        status: FeedbackStatus.OPEN,
      });

      expect(result.items).toHaveLength(1);
      expect(result.items[0].user.id).toBe('user-1');
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
    });

    it('does not expose private user data', async () => {
      database.feedback.findMany.mockResolvedValue([
        {
          id: 'f-1',
          type: FeedbackType.BUG,
          message: 'Bug',
          status: FeedbackStatus.OPEN,
          createdAt: new Date(),
          appVersion: null,
          platform: null,
          user: { id: 'user-1', name: 'User A' },
        },
      ]);
      database.feedback.count.mockResolvedValue(1);

      const result = await service.getFeedbacks({ page: 1, limit: 10 });

      expect((result.items[0] as any).user.phone).toBeUndefined();
      expect((result.items[0] as any).user.email).toBeUndefined();
      expect((result.items[0] as any).user.location).toBeUndefined();
    });
  });

  describe('getFeedbackDetail', () => {
    it('returns feedback detail', async () => {
      database.feedback.findFirst.mockResolvedValue({
        id: 'f-1',
        type: FeedbackType.BUG,
        message: 'Bug',
        status: FeedbackStatus.OPEN,
        createdAt: new Date(),
        updatedAt: new Date(),
        appVersion: '1.0.0',
        platform: 'android',
        resolvedAt: null,
        user: { id: 'user-1', name: 'User A' },
      });

      const result = await service.getFeedbackDetail('f-1');

      expect(result.id).toBe('f-1');
      expect(result.user.id).toBe('user-1');
      expect(result.user.name).toBe('User A');
    });

    it('throws NotFoundException when feedback does not exist', async () => {
      database.feedback.findFirst.mockResolvedValue(null);

      await expect(service.getFeedbackDetail('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('updateStatus', () => {
    it('updates OPEN to REVIEWED and logs audit', async () => {
      database.feedback.findFirst.mockResolvedValue({
        id: 'f-1',
        status: FeedbackStatus.OPEN,
      });
      database.feedback.update.mockResolvedValue({ id: 'f-1', status: FeedbackStatus.REVIEWED });

      const result = await service.updateStatus(
        'actor-1',
        'f-1',
        FeedbackStatus.REVIEWED,
      );

      expect(result).toEqual({ id: 'f-1', status: FeedbackStatus.REVIEWED });
      expect(database.feedback.update).toHaveBeenCalledWith({
        where: { id: 'f-1' },
        data: { status: FeedbackStatus.REVIEWED, resolvedAt: null },
      });
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith({
        data: {
          feedbackId: 'f-1',
          action: ModerationAuditAction.FEEDBACK_STATUS_UPDATED,
          actorId: 'actor-1',
        },
      });
    });

    it('updates REVIEWED to RESOLVED and sets resolvedAt', async () => {
      database.feedback.findFirst.mockResolvedValue({
        id: 'f-1',
        status: FeedbackStatus.REVIEWED,
      });
      database.feedback.update.mockResolvedValue({
        id: 'f-1',
        status: FeedbackStatus.RESOLVED,
      });

      const result = await service.updateStatus(
        'actor-1',
        'f-1',
        FeedbackStatus.RESOLVED,
      );

      expect(result.status).toBe(FeedbackStatus.RESOLVED);
      expect(database.feedback.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: FeedbackStatus.RESOLVED,
            resolvedAt: expect.any(Date),
          }),
        }),
      );
    });

    it('rejects same-status update', async () => {
      database.feedback.findFirst.mockResolvedValue({
        id: 'f-1',
        status: FeedbackStatus.OPEN,
      });

      await expect(
        service.updateStatus('actor-1', 'f-1', FeedbackStatus.OPEN),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects invalid transitions', async () => {
      database.feedback.findFirst.mockResolvedValue({
        id: 'f-1',
        status: FeedbackStatus.OPEN,
      });

      await expect(
        service.updateStatus('actor-1', 'f-1', FeedbackStatus.RESOLVED),
      ).rejects.toThrow(BadRequestException);
    });

    it('throws NotFoundException for missing feedback', async () => {
      database.feedback.findFirst.mockResolvedValue(null);

      await expect(
        service.updateStatus('actor-1', 'missing', FeedbackStatus.REVIEWED),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
