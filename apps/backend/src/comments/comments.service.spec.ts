import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { CommentStatus, CommentReportReason } from '../generated/prisma/client';
import { CommentsService } from './comments.service';

describe('CommentsService', () => {
  let service: CommentsService;
  let databaseService: any;

  beforeEach(async () => {
    databaseService = {
      post: {
        findFirst: jest.fn(),
      },
      comment: {
        findMany: jest.fn(),
        count: jest.fn(),
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      commentReport: {
        findUnique: jest.fn(),
        create: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommentsService,
        { provide: DatabaseService, useValue: databaseService },
      ],
    }).compile();

    service = module.get<CommentsService>(CommentsService);
  });

  describe('listComments', () => {
    it('returns paginated active comments for an existing post', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findMany.mockResolvedValue([
        {
          id: 'comment-1',
          content: 'Hello world',
          status: CommentStatus.ACTIVE,
          createdAt: new Date('2026-08-13T10:00:00Z'),
          deletedAt: null,
          user: { id: 'user-1', name: 'Amit' },
        },
      ]);
      databaseService.comment.count.mockResolvedValue(1);
      databaseService.comment.groupBy = jest.fn().mockResolvedValue([]);

      const result = await service.listComments('post-1', 1, 20);

      expect(result.items.length).toBe(1);
      expect(result.items[0].id).toBe('comment-1');
      expect(result.items[0].author.name).toBe('Amit');
      expect(result.total).toBe(1);
      expect(result.hasMore).toBe(false);
    });

    it('throws 404 if post does not exist or is soft-deleted', async () => {
      databaseService.post.findFirst.mockResolvedValue(null);

      await expect(service.listComments('deleted-post')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('createComment', () => {
    it('creates a top-level active comment using JWT user ID', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.create.mockResolvedValue({
        id: 'comment-100',
        content: 'New comment',
        createdAt: new Date('2026-08-13T11:00:00Z'),
        user: { id: 'user-123', name: 'User 123' },
      });

      const result = await service.createComment('user-123', 'post-1', {
        content: 'New comment',
      });

      expect(result.id).toBe('comment-100');
      expect(result.content).toBe('New comment');
      expect(databaseService.comment.create).toHaveBeenCalledWith({
        data: {
          postId: 'post-1',
          userId: 'user-123',
          content: 'New comment',
          status: CommentStatus.ACTIVE,
          parentId: null,
        },
        select: expect.any(Object),
      });
    });

    it('throws 404 when creating comment on soft-deleted post', async () => {
      databaseService.post.findFirst.mockResolvedValue(null);

      await expect(
        service.createComment('user-123', 'deleted-post', { content: 'test' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deleteComment', () => {
    it('allows comment author to delete their own comment', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({
        id: 'comment-1',
        userId: 'user-123',
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      });

      const result = await service.deleteComment('user-123', 'post-1', 'comment-1');

      expect(result).toEqual({ success: true });
      expect(databaseService.comment.update).toHaveBeenCalledWith({
        where: { id: 'comment-1' },
        data: {
          status: CommentStatus.DELETED,
          deletedAt: expect.any(Date),
        },
      });
    });

    it('throws 403 Forbidden when a user tries to delete another user comment', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({
        id: 'comment-1',
        userId: 'owner-user',
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      });

      await expect(
        service.deleteComment('attacker-user', 'post-1', 'comment-1'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws 404 when comment does not exist or post is soft-deleted', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue(null);

      await expect(
        service.deleteComment('user-123', 'post-1', 'missing-comment'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('reportComment', () => {
    it('creates a comment report', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({ id: 'comment-1' });
      databaseService.commentReport.findUnique.mockResolvedValue(null);
      databaseService.commentReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
        createdAt: new Date(),
      });

      const result = await service.reportComment('reporter-1', 'post-1', 'comment-1', {
        reason: CommentReportReason.SPAM,
        description: 'Spammy text',
      });

      expect(result.id).toBe('report-1');
      expect(databaseService.commentReport.create).toHaveBeenCalledWith({
        data: {
          commentId: 'comment-1',
          reporterId: 'reporter-1',
          reason: CommentReportReason.SPAM,
          description: 'Spammy text',
        },
        select: expect.any(Object),
      });
    });

    it('throws 409 Conflict on duplicate report by same reporter', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({ id: 'comment-1' });
      databaseService.commentReport.findUnique.mockResolvedValue({ id: 'report-1' });

      await expect(
        service.reportComment('reporter-1', 'post-1', 'comment-1', {
          reason: CommentReportReason.SPAM,
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('createReply', () => {
    it('creates a reply to an active comment successfully', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({
        id: 'comment-1',
        postId: 'post-1',
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      });

      databaseService.comment.create.mockResolvedValue({
        id: 'reply-1',
        postId: 'post-1',
        parentId: 'comment-1',
        content: 'This is a reply',
        status: CommentStatus.ACTIVE,
        createdAt: new Date('2026-08-13T12:00:00Z'),
        user: { id: 'user-456', name: 'Amit' },
      });

      const result = await service.createReply('user-456', 'post-1', 'comment-1', {
        content: 'This is a reply',
      });

      expect(result.id).toBe('reply-1');
      expect(result.parentId).toBe('comment-1');
      expect(result.author.name).toBe('Amit');
    });

    it('throws 404 if parent comment does not exist or is soft-deleted', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue(null);

      await expect(
        service.createReply('user-456', 'post-1', 'comment-deleted-or-missing', {
          content: 'This is a reply',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('listReplies', () => {
    it('returns direct replies sorted chronologically', async () => {
      databaseService.post.findFirst.mockResolvedValue({ id: 'post-1' });
      databaseService.comment.findFirst.mockResolvedValue({
        id: 'comment-1',
        postId: 'post-1',
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      });

      databaseService.comment.findMany.mockResolvedValue([
        {
          id: 'reply-1',
          parentId: 'comment-1',
          content: 'Direct reply',
          status: CommentStatus.ACTIVE,
          createdAt: new Date('2026-08-13T12:05:00Z'),
          deletedAt: null,
          user: { id: 'user-3', name: 'Zoya' },
        },
      ]);
      databaseService.comment.count.mockResolvedValue(1);
      databaseService.comment.groupBy = jest.fn().mockResolvedValue([]);

      const result = await service.listReplies('post-1', 'comment-1', 1, 20);

      expect(result.items.length).toBe(1);
      expect(result.items[0].id).toBe('reply-1');
      expect(result.items[0].parentId).toBe('comment-1');
      expect(result.items[0].content).toBe('Direct reply');
    });
  });
});
