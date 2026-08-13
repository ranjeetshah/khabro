import { Test, TestingModule } from '@nestjs/testing';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CommentsController } from './comments.controller';
import { CommentsService } from './comments.service';
import { CommentReportReason } from '../generated/prisma/client';

describe('CommentsController', () => {
  let controller: CommentsController;
  let service: any;

  beforeEach(async () => {
    service = {
      listComments: jest.fn(),
      createComment: jest.fn(),
      deleteComment: jest.fn(),
      reportComment: jest.fn(),
      createReply: jest.fn(),
      listReplies: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CommentsController],
      providers: [{ provide: CommentsService, useValue: service }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<CommentsController>(CommentsController);
  });

  it('delegates listComments with default pagination', async () => {
    service.listComments.mockResolvedValue({ items: [], page: 1, limit: 20, total: 0, hasMore: false });

    const result = await controller.listComments('post-1', '1', '20');

    expect(service.listComments).toHaveBeenCalledWith('post-1', 1, 20);
    expect(result.items).toEqual([]);
  });

  it('delegates createComment using JWT sub', async () => {
    const mockReq = { user: { sub: 'user-123' } };
    service.createComment.mockResolvedValue({ id: 'comment-1', content: 'Test' });

    const result = await controller.createComment(mockReq, 'post-1', { content: 'Test' });

    expect(service.createComment).toHaveBeenCalledWith('user-123', 'post-1', { content: 'Test' });
    expect(result.id).toBe('comment-1');
  });

  it('delegates deleteComment using JWT sub', async () => {
    const mockReq = { user: { sub: 'user-123' } };
    service.deleteComment.mockResolvedValue({ success: true });

    const result = await controller.deleteComment(mockReq, 'post-1', 'comment-1');

    expect(service.deleteComment).toHaveBeenCalledWith('user-123', 'post-1', 'comment-1');
    expect(result.success).toBe(true);
  });

  it('delegates reportComment using JWT sub', async () => {
    const mockReq = { user: { sub: 'user-123' } };
    service.reportComment.mockResolvedValue({ id: 'report-1', status: 'OPEN' });

    const result = await controller.reportComment(mockReq, 'post-1', 'comment-1', {
      reason: CommentReportReason.SPAM,
    });

    expect(service.reportComment).toHaveBeenCalledWith('user-123', 'post-1', 'comment-1', {
      reason: CommentReportReason.SPAM,
    });
    expect(result.id).toBe('report-1');
  });

  it('delegates createReply using JWT sub', async () => {
    const mockReq = { user: { sub: 'user-123' } };
    service.createReply.mockResolvedValue({ id: 'reply-1', content: 'Reply content' });

    const result = await controller.createReply(mockReq, 'post-1', 'comment-1', { content: 'Reply content' });

    expect(service.createReply).toHaveBeenCalledWith('user-123', 'post-1', 'comment-1', { content: 'Reply content' });
    expect(result.id).toBe('reply-1');
  });

  it('delegates listReplies with default pagination', async () => {
    service.listReplies.mockResolvedValue({ items: [], page: 1, limit: 20, total: 0, hasMore: false });

    const result = await controller.listReplies('post-1', 'comment-1', '1', '20');

    expect(service.listReplies).toHaveBeenCalledWith('post-1', 'comment-1', 1, 20);
    expect(result.items).toEqual([]);
  });
});
