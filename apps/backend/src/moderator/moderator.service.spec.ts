import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { ModeratorService } from './moderator.service';
import { ReportStatus, CivicComplaintStatus, ModerationAuditAction } from '../generated/prisma/enums';

describe('ModeratorService', () => {
  let service: ModeratorService;

  const database = {
    postReport: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    userReport: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    commentReport: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    civicComplaint: {
      count: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
    civicComplaintStatusHistory: {
      findMany: jest.fn(),
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
        ModeratorService,
        { provide: DatabaseService, useValue: database },
      ],
    }).compile();
    service = module.get(ModeratorService);
  });

  it('is defined', () => expect(service).toBeDefined());

  describe('getDashboardCounts', () => {
    it('returns dashboard counts using db count', async () => {
      database.postReport.count.mockResolvedValue(5);
      database.userReport.count.mockResolvedValue(2);
      database.commentReport.count.mockResolvedValue(3);
      database.civicComplaint.count.mockResolvedValue(4);

      const result = await service.getDashboardCounts();

      expect(result).toEqual({
        openPostReports: 5,
        openUserReports: 2,
        openCommentReports: 3,
        activeCivicComplaints: 4,
      });

      expect(database.postReport.count).toHaveBeenCalledWith({ where: { status: 'OPEN' } });
      expect(database.civicComplaint.count).toHaveBeenCalledWith({
        where: {
          status: {
            in: ['SENT', 'ACKNOWLEDGED', 'IN_PROGRESS', 'REOPENED'],
          },
        },
      });
    });
  });

  describe('getReports', () => {
    it('filters by post type and status pagination', async () => {
      const mockPostReport = {
        id: 'r-1',
        reason: 'SPAM',
        description: 'Spammy',
        status: 'OPEN',
        createdAt: new Date('2026-08-13T00:00:00Z'),
        post: { id: 'p-1', content: 'hello world' },
      };

      database.postReport.findMany.mockResolvedValue([mockPostReport]);
      database.postReport.count.mockResolvedValue(1);

      const result = await service.getReports({
        page: 1,
        limit: 10,
        type: 'POST',
        status: ReportStatus.OPEN,
      });

      expect(result.items).toHaveLength(1);
      expect(result.items[0]).toEqual(
        expect.objectContaining({
          id: 'r-1',
          type: 'POST',
          reason: 'SPAM',
          description: 'Spammy',
          status: 'OPEN',
          target: { id: 'p-1', title: 'hello world' },
        }),
      );
      expect(database.postReport.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { status: 'OPEN' },
          take: 10,
        }),
      );
    });

    it('returns combined reports list sorted by createdAt desc', async () => {
      const pReport = {
        id: 'r-post',
        reason: 'SPAM',
        description: 'spam',
        status: 'OPEN',
        createdAt: new Date('2026-08-13T10:00:00Z'),
        post: { id: 'post-1', content: 'post body' },
      };
      const uReport = {
        id: 'r-user',
        reason: 'HARASSMENT',
        description: 'harr',
        status: 'OPEN',
        createdAt: new Date('2026-08-13T11:00:00Z'),
        reportedUser: { id: 'user-1', name: 'User A', phone: '+919999999999' },
      };
      const cReport = {
        id: 'r-comment',
        reason: 'ABUSE',
        description: 'abuse',
        status: 'OPEN',
        createdAt: new Date('2026-08-13T09:00:00Z'),
        comment: { id: 'c-1', content: 'comment body' },
      };

      database.postReport.findMany.mockResolvedValue([pReport]);
      database.userReport.findMany.mockResolvedValue([uReport]);
      database.commentReport.findMany.mockResolvedValue([cReport]);

      database.postReport.count.mockResolvedValue(1);
      database.userReport.count.mockResolvedValue(1);
      database.commentReport.count.mockResolvedValue(1);

      const result = await service.getReports({ page: 1, limit: 10 });

      expect(result.total).toBe(3);
      expect(result.items).toHaveLength(3);
      // Sorted desc: user (11:00) -> post (10:00) -> comment (09:00)
      expect(result.items[0].id).toBe('r-user');
      expect(result.items[1].id).toBe('r-post');
      expect(result.items[2].id).toBe('r-comment');
    });
  });

  describe('getReportDetail', () => {
    it('returns post report details safely', async () => {
      const mockPostReport = {
        id: 'r-1',
        reason: 'SPAM',
        description: 'Spammy',
        status: 'OPEN',
        createdAt: new Date(),
        post: {
          id: 'p-1',
          content: 'spam post content',
          verificationStatus: 'UNDER_VERIFICATION',
          witnesses: [{ id: 'w-1' }, { id: 'w-2' }],
          author: { id: 'author-1', name: 'John Doe' },
        },
      };

      database.postReport.findUnique.mockResolvedValue(mockPostReport);

      const result = await service.getReportDetail('r-1');

      expect(result.id).toBe('r-1');
      expect(result.type).toBe('POST');
      expect(result.post.witnessCount).toBe(2);
      expect(result.post.author.name).toBe('John Doe');
      expect((result as any).reporterId).toBeUndefined();
    });

    it('throws NotFoundException when no report matches id', async () => {
      database.postReport.findUnique.mockResolvedValue(null);
      database.userReport.findUnique.mockResolvedValue(null);
      database.commentReport.findUnique.mockResolvedValue(null);

      await expect(service.getReportDetail('r-invalid')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('updateReportStatus', () => {
    it('updates status and logs audit event', async () => {
      database.postReport.findUnique.mockResolvedValue({ id: 'r-1', status: 'OPEN' });
      database.postReport.update.mockResolvedValue({ id: 'r-1', status: 'REVIEWED' });

      const result = await service.updateReportStatus('actor-123', 'r-1', ReportStatus.REVIEWED);

      expect(result).toEqual({ id: 'r-1', status: 'REVIEWED' });
      expect(database.postReport.update).toHaveBeenCalledWith({
        where: { id: 'r-1' },
        data: { status: 'REVIEWED' },
      });
      expect(database.moderationAuditEvent.create).toHaveBeenCalledWith({
        data: {
          reportId: 'r-1',
          action: ModerationAuditAction.REPORT_REVIEWED,
          actorId: 'actor-123',
        },
      });
    });

    it('throws BadRequestException if report already resolved or dismissed', async () => {
      database.postReport.findUnique.mockResolvedValue({ id: 'r-1', status: 'RESOLVED' });

      await expect(
        service.updateReportStatus('actor-123', 'r-1', ReportStatus.REVIEWED),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('civic complaints', () => {
    it('returns civic complaints lists with safe attributes', async () => {
      const mockComplaint = {
        id: 'c-1',
        referenceCode: 'KH-2026-111111',
        status: 'SENT',
        witnessCount: 15,
        createdAt: new Date(),
        sentAt: new Date(),
        updatedAt: new Date(),
      };

      database.civicComplaint.findMany.mockResolvedValue([mockComplaint]);
      database.civicComplaint.count.mockResolvedValue(1);

      const result = await service.getCivicComplaints({ page: 1, limit: 10 });

      expect(result.items).toHaveLength(1);
      expect(result.items[0]).toEqual(mockComplaint);
    });

    it('returns detail history ordered by createdAt asc and id asc, omitting actorId', async () => {
      const mockComplaint = {
        id: 'cc-1',
        referenceCode: 'KH-2026-111111',
        status: 'IN_PROGRESS',
        witnessCount: 22,
        createdAt: new Date(),
        sentAt: new Date(),
        updatedAt: new Date(),
      };
      const mockHistory = [
        {
          id: 'hist-1',
          fromStatus: 'SENT',
          toStatus: 'ACKNOWLEDGED',
          note: 'Ok',
          actorId: 'private-actor-id',
          createdAt: new Date('2026-08-13T10:00:00Z'),
        },
      ];

      database.civicComplaint.findFirst.mockResolvedValue(mockComplaint);
      database.civicComplaintStatusHistory.findMany.mockResolvedValue(mockHistory);

      const result = await service.getCivicComplaintDetail('cc-1');

      expect(result.referenceCode).toBe('KH-2026-111111');
      expect(result.statusHistory).toHaveLength(1);
      expect(result.statusHistory[0].toStatus).toBe('ACKNOWLEDGED');
      expect((result.statusHistory[0] as any).actorId).toBeUndefined();
    });
  });
});
