import { ConflictException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { ComplaintService } from './complaints.service';

describe('ComplaintService', () => {
  let service: ComplaintService;

  const database = {
    post: { findFirst: jest.fn(), update: jest.fn() },
    complaint: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    complaintStatusHistory: { create: jest.fn() },
    $transaction: jest.fn((callback: (tx: any) => Promise<unknown>) =>
      callback(database),
    ),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ComplaintService,
        { provide: DatabaseService, useValue: database },
      ],
    }).compile();
    service = module.get(ComplaintService);
  });

  it('is defined', () => expect(service).toBeDefined());

  describe('create', () => {
    it('creates a SUBMITTED complaint for a LOCALLY_VERIFIED post', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'LOCALLY_VERIFIED',
      });
      database.complaint.findUnique.mockResolvedValue(null);
      database.complaint.create.mockResolvedValue({
        id: 'complaint-1',
        status: 'SUBMITTED',
      });

      const result = await service.create(
        'user-1',
        'post-1',
        'Road is blocked by construction debris.',
      );

      expect(result).toEqual({ id: 'complaint-1', status: 'SUBMITTED' });
      expect(database.complaint.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            postId: 'post-1',
            createdById: 'user-1',
            description: 'Road is blocked by construction debris.',
          },
        }),
      );
      expect(database.$transaction).toHaveBeenCalledTimes(1);
      expect(database.complaintStatusHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            complaintId: 'complaint-1',
            toStatus: 'SUBMITTED',
          },
        }),
      );
    });

    it('rejects a REPORTED post', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'REPORTED',
      });
      await expect(
        service.create('user-1', 'post-1', 'Description here please.'),
      ).rejects.toThrow(ConflictException);
      expect(database.complaint.create).not.toHaveBeenCalled();
    });

    it('rejects an UNDER_VERIFICATION post', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'UNDER_VERIFICATION',
      });
      await expect(
        service.create('user-1', 'post-1', 'Description here please.'),
      ).rejects.toThrow(ConflictException);
    });

    it('rejects a deleted post', async () => {
      database.post.findFirst.mockResolvedValue(null);
      await expect(
        service.create('user-1', 'post-1', 'Description here please.'),
      ).rejects.toThrow(NotFoundException);
    });

    it('queries authoritative post state and never trusts a client flag', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'REPORTED',
      });
      database.complaint.findUnique.mockResolvedValue(null);

      await expect(
        service.create('user-1', 'post-1', 'Description here please.'),
      ).rejects.toThrow(ConflictException);

      expect(database.post.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'post-1', deletedAt: null },
        }),
      );
    });

    it('uses the JWT identity, never a client-createdById', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'LOCALLY_VERIFIED',
      });
      database.complaint.findUnique.mockResolvedValue(null);
      database.complaint.create.mockResolvedValue({
        id: 'complaint-1',
        status: 'SUBMITTED',
      });

      await service.create('jwt-sub-1', 'post-1', 'Description here please.');

      expect(database.complaint.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ createdById: 'jwt-sub-1' }),
        }),
      );
    });

    it('protects against duplicate complaints for the same post', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'LOCALLY_VERIFIED',
      });
      database.complaint.findUnique.mockResolvedValue({ id: 'complaint-1' });

      await expect(
        service.create('user-1', 'post-1', 'Description here please.'),
      ).rejects.toThrow(ConflictException);
      expect(database.complaint.create).not.toHaveBeenCalled();
    });

    it('does not change the verification status of the post', async () => {
      database.post.findFirst.mockResolvedValue({
        id: 'post-1',
        verificationStatus: 'LOCALLY_VERIFIED',
      });
      database.complaint.findUnique.mockResolvedValue(null);
      database.complaint.create.mockResolvedValue({
        id: 'complaint-1',
        status: 'SUBMITTED',
      });

      await service.create('user-1', 'post-1', 'Description here please.');

      expect(database.post.update).not.toHaveBeenCalled();
      expect(
        (database.post.findFirst.mock.calls[0][0] as any).select,
      ).toEqual(expect.objectContaining({ verificationStatus: true }));
    });
  });

  describe('findOne', () => {
    it('returns safe fields plus ordered status history for the owner', async () => {
      database.complaint.findFirst.mockResolvedValue({
        id: 'complaint-1',
        createdById: 'user-1',
        status: 'SUBMITTED',
        description: 'Road is blocked.',
        createdAt: new Date('2026-08-10T00:00:00.000Z'),
        updatedAt: new Date('2026-08-10T00:00:01.000Z'),
        post: { content: 'Road is blocked.', verificationStatus: 'LOCALLY_VERIFIED' },
        statusHistory: [
          {
            fromStatus: null,
            toStatus: 'SUBMITTED',
            createdAt: new Date('2026-08-10T00:00:00.000Z'),
          },
        ],
      });

      const result = await service.findOne('complaint-1', 'user-1');

      expect(result).toEqual({
        id: 'complaint-1',
        status: 'SUBMITTED',
        description: 'Road is blocked.',
        createdAt: new Date('2026-08-10T00:00:00.000Z'),
        updatedAt: new Date('2026-08-10T00:00:01.000Z'),
        post: {
          content: 'Road is blocked.',
          verificationStatus: 'LOCALLY_VERIFIED',
        },
        statusHistory: [
          {
            fromStatus: null,
            toStatus: 'SUBMITTED',
            createdAt: new Date('2026-08-10T00:00:00.000Z'),
          },
        ],
      });
      expect(result).not.toHaveProperty('createdById');
    });

    it('hides another users complaint as if it did not exist', async () => {
      database.complaint.findFirst.mockResolvedValue({
        id: 'complaint-1',
        createdById: 'other-user',
      });
      await expect(
        service.findOne('complaint-1', 'user-1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('returns 404 for a missing complaint', async () => {
      database.complaint.findFirst.mockResolvedValue(null);
      await expect(
        service.findOne('missing', 'user-1'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('findMine', () => {
    it('lists only the current users complaints with cursor pagination', async () => {
      database.complaint.findMany.mockResolvedValue([
        {
          id: 'complaint-2',
          status: 'SUBMITTED',
          description: 'Second issue.',
          createdAt: new Date('2026-08-10T01:00:00.000Z'),
        },
        {
          id: 'complaint-1',
          status: 'SUBMITTED',
          description: 'First issue.',
          createdAt: new Date('2026-08-10T00:00:00.000Z'),
        },
      ]);

      const result = await service.findMine('user-1', 20);

      expect(database.complaint.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { createdById: 'user-1' },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: 21,
        }),
      );
      expect(result.complaints).toHaveLength(2);
      expect(result.nextCursor).toBeNull();
      expect(result.complaints[0]).not.toHaveProperty('createdById');
      expect(result.complaints[0]).not.toHaveProperty('postId');
    });

    it('returns a next cursor when more items exist', async () => {
      const items = Array.from({ length: 21 }, (_, i) => ({
        id: `complaint-${i}`,
        status: 'SUBMITTED',
        description: 'Issue.',
        createdAt: new Date(2026, 0, 1, 0, i),
      }));
      database.complaint.findMany.mockResolvedValue(items);

      const result = await service.findMine('user-1', 20);

      expect(result.complaints).toHaveLength(20);
      expect(result.nextCursor).toEqual(expect.any(String));
    });

    it('decodes a cursor into a where clause', async () => {
      database.complaint.findMany.mockResolvedValue([]);
      const cursor = Buffer.from(
        JSON.stringify({
          createdAt: '2026-08-10T00:00:00.000Z',
          id: 'complaint-1',
        }),
      ).toString('base64');

      await service.findMine('user-1', 20, cursor);

      expect(database.complaint.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            createdById: 'user-1',
            OR: [
              { createdAt: { lt: new Date('2026-08-10T00:00:00.000Z') } },
              {
                createdAt: new Date('2026-08-10T00:00:00.000Z'),
                id: { lt: 'complaint-1' },
              },
            ],
          },
        }),
      );
    });
  });

  describe('transition (internal)', () => {
    it('rejects unknown complaints', async () => {
      database.complaint.findUnique.mockResolvedValue(null);
      await expect(service.transition('missing', 'ACKNOWLEDGED')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('rejects a no-op transition', async () => {
      database.complaint.findUnique.mockResolvedValue({
        id: 'complaint-1',
        status: 'SUBMITTED',
      });
      await expect(
        service.transition('complaint-1', 'SUBMITTED'),
      ).rejects.toThrow(ConflictException);
    });
  });
});
