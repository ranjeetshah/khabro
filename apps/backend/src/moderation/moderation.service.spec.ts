import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { ModerationService } from './moderation.service';

describe('ModerationService', () => {
  let service: ModerationService;

  const database = {
    post: { findFirst: jest.fn() },
    user: { findUnique: jest.fn() },
    postReport: {
      findFirst: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    userReport: {
      findFirst: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    moderationAuditEvent: { create: jest.fn() },
    $transaction: jest.fn((callback: (tx: any) => Promise<unknown>) =>
      callback(database),
    ),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModerationService,
        { provide: DatabaseService, useValue: database },
      ],
    }).compile();
    service = module.get(ModerationService);
  });

  it('is defined', () => expect(service).toBeDefined());

  describe('createPostReport', () => {
    it('creates an OPEN report using JWT reporter identity and audits it', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      const result = await service.createPostReport(
        'reporter-1',
        'post-1',
        'SPAM',
        'Looks like an ad.',
      );

      expect(result).toEqual({ id: 'report-1', status: 'OPEN' });
      expect(database.post.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'post-1', deletedAt: null },
        }),
      );
      expect(database.postReport.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            postId: 'post-1',
            reporterId: 'reporter-1',
            reason: 'SPAM',
            description: 'Looks like an ad.',
          },
        }),
      );
      expect(database.$transaction).toHaveBeenCalledTimes(1);
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            reportId: 'report-1',
            action: 'REPORT_CREATED',
          },
        }),
      );
    });

    it('never accepts a client-supplied reporter identity', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      await service.createPostReport('jwt-sub-1', 'post-1', 'OTHER');

      expect(database.postReport.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ reporterId: 'jwt-sub-1' }),
        }),
      );
      expect(database.postReport.create).not.toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ reporterId: 'client-chosen-id' }),
        }),
      );
    });

    it('rejects reporting a deleted post', async () => {
      database.post.findFirst.mockResolvedValue(null);
      await expect(
        service.createPostReport('user-1', 'post-1', 'SPAM'),
      ).rejects.toThrow(NotFoundException);
      expect(database.postReport.create).not.toHaveBeenCalled();
    });

    it('returns 404 for a missing post', async () => {
      database.post.findFirst.mockResolvedValue(null);
      await expect(
        service.createPostReport('user-1', 'missing-post', 'SPAM'),
      ).rejects.toThrow(NotFoundException);
    });

    it('blocks an obvious duplicate report while one is open', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue({ id: 'report-1' });

      await expect(
        service.createPostReport('user-1', 'post-1', 'SPAM'),
      ).rejects.toThrow(ConflictException);
      expect(database.postReport.create).not.toHaveBeenCalled();
    });

    it('allows a different reason after the first report is finalized', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-2',
        status: 'OPEN',
      });

      await service.createPostReport('user-1', 'post-1', 'DANGEROUS_CONTENT');

      expect(database.postReport.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ reason: 'DANGEROUS_CONTENT' }),
        }),
      );
    });

    it('trims an empty description to null', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-3',
        status: 'OPEN',
      });

      await service.createPostReport('user-1', 'post-1', 'SPAM', '   ');

      expect(database.postReport.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ description: null }),
        }),
      );
    });

    it('exposes only id and status in the response', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
        reporterId: 'reporter-1',
        description: 'secret',
        postId: 'post-1',
      });

      const result = await service.createPostReport(
        'reporter-1',
        'post-1',
        'SPAM',
      );

      expect(result).toEqual({ id: 'report-1', status: 'OPEN' });
      expect(result).not.toHaveProperty('reporterId');
      expect(result).not.toHaveProperty('description');
      expect(result).not.toHaveProperty('postId');
    });
  });

  describe('createUserReport', () => {
    it('creates a user report for another user', async () => {
      database.user.findUnique.mockResolvedValue({ id: 'target-1' });
      database.userReport.findFirst.mockResolvedValue(null);
      database.userReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      const result = await service.createUserReport(
        'reporter-1',
        'target-1',
        'HARASSMENT',
      );

      expect(result).toEqual({ id: 'report-1', status: 'OPEN' });
      expect(database.userReport.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            reportedUserId: 'target-1',
            reporterId: 'reporter-1',
            reason: 'HARASSMENT',
            description: null,
          },
        }),
      );
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ action: 'REPORT_CREATED' }),
        }),
      );
    });

    it('rejects reporting yourself', async () => {
      await expect(
        service.createUserReport('user-1', 'user-1', 'SPAM'),
      ).rejects.toThrow(BadRequestException);
      expect(database.userReport.create).not.toHaveBeenCalled();
    });

    it('returns 404 for an invalid user target', async () => {
      database.user.findUnique.mockResolvedValue(null);
      await expect(
        service.createUserReport('reporter-1', 'missing-user', 'SPAM'),
      ).rejects.toThrow(NotFoundException);
    });

    it('does not expose private target information in the response', async () => {
      database.user.findUnique.mockResolvedValue({ id: 'target-1' });
      database.userReport.findFirst.mockResolvedValue(null);
      database.userReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
        reportedUserId: 'target-1',
        reporterId: 'reporter-1',
      });

      const result = await service.createUserReport(
        'reporter-1',
        'target-1',
        'OTHER',
      );

      expect(result).toEqual({ id: 'report-1', status: 'OPEN' });
      expect(result).not.toHaveProperty('reportedUserId');
    });
  });

  describe('moderator lifecycle (backend-only)', () => {
    it('marks a post report reviewed and audits it', async () => {
      database.postReport.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      const result = await service.reviewPostReport('report-1');

      expect(result).toEqual({ id: 'report-1', status: 'REVIEWED' });
      expect(database.postReport.update).toHaveBeenCalledWith({
        where: { id: 'report-1' },
        data: { status: 'REVIEWED' },
      });
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { reportId: 'report-1', action: 'REPORT_REVIEWED' },
        }),
      );
    });

    it('cannot review a report that is not open', async () => {
      database.postReport.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'RESOLVED',
      });
      await expect(service.reviewPostReport('report-1')).rejects.toThrow(
        BadRequestException,
      );
      expect(database.postReport.update).not.toHaveBeenCalled();
    });

    it('resolves a user report and audits it', async () => {
      database.userReport.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      const result = await service.resolveUserReport('report-1');

      expect(result).toEqual({ id: 'report-1', status: 'RESOLVED' });
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { reportId: 'report-1', action: 'REPORT_RESOLVED' },
        }),
      );
    });

    it('dismisses a post report and audits it', async () => {
      database.postReport.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      const result = await service.dismissPostReport('report-1');

      expect(result).toEqual({ id: 'report-1', status: 'DISMISSED' });
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { reportId: 'report-1', action: 'REPORT_DISMISSED' },
        }),
      );
    });

    it('cannot finalize an already-finalized report', async () => {
      database.postReport.findUnique.mockResolvedValue({
        id: 'report-1',
        status: 'DISMISSED',
      });
      await expect(service.resolvePostReport('report-1')).rejects.toThrow(
        BadRequestException,
      );
      expect(database.postReport.update).not.toHaveBeenCalled();
    });

    it('returns 404 for an unknown report', async () => {
      database.postReport.findUnique.mockResolvedValue(null);
      await expect(service.reviewPostReport('missing')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('audit trail', () => {
    it('records report lifecycle actions end to end', async () => {
      database.post.findFirst.mockResolvedValue({ id: 'post-1' });
      database.postReport.findFirst.mockResolvedValue(null);
      database.postReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });
      database.postReport.findUnique
        .mockResolvedValueOnce({ id: 'report-1', status: 'OPEN' })
        .mockResolvedValueOnce({ id: 'report-1', status: 'REVIEWED' });

      await service.createPostReport('user-1', 'post-1', 'SPAM');
      await service.reviewPostReport('report-1');
      await service.dismissPostReport('report-1');

      const actions = database.moderationAuditEvent.create.mock.calls.map(
        (call) => call[0].data.action,
      );
      expect(actions).toEqual([
        'REPORT_CREATED',
        'REPORT_REVIEWED',
        'REPORT_DISMISSED',
      ]);
    });
  });
});
