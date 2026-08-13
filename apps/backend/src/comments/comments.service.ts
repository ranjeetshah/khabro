import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { CommentStatus } from '../generated/prisma/client';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ReportCommentDto } from './dto/report-comment.dto';

@Injectable()
export class CommentsService {
  constructor(private readonly database: DatabaseService) {}

  async listComments(postId: string, page = 1, limit = 20) {
    await this.assertPostExists(postId);

    const validatedPage = Math.max(1, page);
    const validatedLimit = Math.min(50, Math.max(1, limit));
    const skip = (validatedPage - 1) * validatedLimit;

    // Root comments are parentId = null. Include active ones OR deleted ones if they have active children.
    const where = {
      postId,
      parentId: null,
      OR: [
        {
          status: CommentStatus.ACTIVE,
          deletedAt: null,
        },
        {
          status: CommentStatus.DELETED,
          children: {
            some: {
              status: CommentStatus.ACTIVE,
              deletedAt: null,
            },
          },
        },
        {
          deletedAt: { not: null },
          children: {
            some: {
              status: CommentStatus.ACTIVE,
              deletedAt: null,
            },
          },
        },
      ],
    };

    const [items, total] = await Promise.all([
      this.database.comment.findMany({
        where,
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        skip,
        take: validatedLimit,
        select: {
          id: true,
          content: true,
          status: true,
          createdAt: true,
          updatedAt: true,
          deletedAt: true,
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      this.database.comment.count({ where }),
    ]);

    const commentIds = items.map((item) => item.id);
    const replyCounts = await this.database.comment.groupBy({
      by: ['parentId'],
      where: {
        parentId: { in: commentIds },
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      },
      _count: { id: true },
    });

    const replyCountMap = new Map<string, number>(
      replyCounts
        .filter((c) => c.parentId !== null)
        .map((c) => [c.parentId!, c._count.id])
    );

    const formattedItems = items.map((comment) => {
      const isDeleted = comment.deletedAt !== null || comment.status === CommentStatus.DELETED;
      const count = replyCountMap.get(comment.id) || 0;

      if (isDeleted) {
        return {
          id: comment.id,
          content: null,
          status: CommentStatus.DELETED,
          deleted: true,
          createdAt: comment.createdAt,
          author: null,
          replyCount: count,
        };
      }

      return {
        id: comment.id,
        content: comment.content,
        status: comment.status,
        createdAt: comment.createdAt,
        author: {
          id: comment.user.id,
          name: comment.user.name ?? 'Anonymous',
        },
        replyCount: count,
      };
    });

    return {
      items: formattedItems,
      page: validatedPage,
      limit: validatedLimit,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async createComment(userId: string, postId: string, dto: CreateCommentDto) {
    await this.assertPostExists(postId);

    const comment = await this.database.comment.create({
      data: {
        postId,
        userId,
        content: dto.content,
        status: CommentStatus.ACTIVE,
        parentId: null,
      },
      select: {
        id: true,
        content: true,
        createdAt: true,
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    return {
      id: comment.id,
      content: comment.content,
      createdAt: comment.createdAt,
      author: {
        id: comment.user.id,
        name: comment.user.name ?? 'Anonymous',
      },
    };
  }

  async createReply(userId: string, postId: string, commentId: string, dto: CreateCommentDto) {
    await this.assertPostExists(postId);

    const parent = await this.database.comment.findFirst({
      where: {
        id: commentId,
        postId,
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      },
    });

    if (!parent) {
      throw new NotFoundException('Parent comment not found');
    }

    const reply = await this.database.comment.create({
      data: {
        postId,
        userId,
        parentId: commentId,
        content: dto.content,
        status: CommentStatus.ACTIVE,
      },
      select: {
        id: true,
        parentId: true,
        postId: true,
        content: true,
        status: true,
        createdAt: true,
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    return {
      id: reply.id,
      postId: reply.postId,
      parentId: reply.parentId,
      content: reply.content,
      status: reply.status,
      createdAt: reply.createdAt,
      author: {
        id: reply.user.id,
        name: reply.user.name ?? 'Anonymous',
      },
    };
  }

  async listReplies(postId: string, commentId: string, page = 1, limit = 20) {
    await this.assertPostExists(postId);

    const parent = await this.database.comment.findFirst({
      where: {
        id: commentId,
        postId,
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      },
    });

    if (!parent) {
      throw new NotFoundException('Parent comment not found');
    }

    const validatedPage = Math.max(1, page);
    const validatedLimit = Math.min(50, Math.max(1, limit));
    const skip = (validatedPage - 1) * validatedLimit;

    // Direct replies are parentId = commentId. Include active ones OR deleted ones if they have active children.
    const where = {
      postId,
      parentId: commentId,
      OR: [
        {
          status: CommentStatus.ACTIVE,
          deletedAt: null,
        },
        {
          status: CommentStatus.DELETED,
          children: {
            some: {
              status: CommentStatus.ACTIVE,
              deletedAt: null,
            },
          },
        },
        {
          deletedAt: { not: null },
          children: {
            some: {
              status: CommentStatus.ACTIVE,
              deletedAt: null,
            },
          },
        },
      ],
    };

    const [items, total] = await Promise.all([
      this.database.comment.findMany({
        where,
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        skip,
        take: validatedLimit,
        select: {
          id: true,
          parentId: true,
          content: true,
          status: true,
          createdAt: true,
          updatedAt: true,
          deletedAt: true,
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      this.database.comment.count({ where }),
    ]);

    const replyIds = items.map((item) => item.id);
    const replyCounts = await this.database.comment.groupBy({
      by: ['parentId'],
      where: {
        parentId: { in: replyIds },
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      },
      _count: { id: true },
    });

    const replyCountMap = new Map<string, number>(
      replyCounts
        .filter((c) => c.parentId !== null)
        .map((c) => [c.parentId!, c._count.id])
    );

    const formattedItems = items.map((comment) => {
      const isDeleted = comment.deletedAt !== null || comment.status === CommentStatus.DELETED;
      const count = replyCountMap.get(comment.id) || 0;

      if (isDeleted) {
        return {
          id: comment.id,
          parentId: comment.parentId,
          content: null,
          status: CommentStatus.DELETED,
          deleted: true,
          createdAt: comment.createdAt,
          author: null,
          replyCount: count,
        };
      }

      return {
        id: comment.id,
        parentId: comment.parentId,
        content: comment.content,
        status: comment.status,
        createdAt: comment.createdAt,
        author: {
          id: comment.user.id,
          name: comment.user.name ?? 'Anonymous',
        },
        replyCount: count,
      };
    });

    return {
      items: formattedItems,
      page: validatedPage,
      limit: validatedLimit,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async deleteComment(userId: string, postId: string, commentId: string) {
    await this.assertPostExists(postId);

    const comment = await this.database.comment.findFirst({
      where: {
        id: commentId,
        postId,
      },
      select: {
        id: true,
        userId: true,
        status: true,
        deletedAt: true,
      },
    });

    if (!comment || comment.deletedAt !== null || comment.status === CommentStatus.DELETED) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.userId !== userId) {
      throw new ForbiddenException('You can only delete your own comment');
    }

    await this.database.comment.update({
      where: { id: commentId },
      data: {
        status: CommentStatus.DELETED,
        deletedAt: new Date(),
      },
    });

    return { success: true };
  }

  async reportComment(
    userId: string,
    postId: string,
    commentId: string,
    dto: ReportCommentDto,
  ) {
    await this.assertPostExists(postId);

    const comment = await this.database.comment.findFirst({
      where: {
        id: commentId,
        postId,
        status: CommentStatus.ACTIVE,
        deletedAt: null,
      },
      select: { id: true },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    const existingReport = await this.database.commentReport.findUnique({
      where: {
        commentId_reporterId: {
          commentId,
          reporterId: userId,
        },
      },
    });

    if (existingReport) {
      throw new ConflictException('Comment already reported');
    }

    const report = await this.database.commentReport.create({
      data: {
        commentId,
        reporterId: userId,
        reason: dto.reason,
        description: dto.description,
      },
      select: {
        id: true,
        status: true,
        createdAt: true,
      },
    });

    return report;
  }

  private async assertPostExists(postId: string) {
    const post = await this.database.post.findFirst({
      where: {
        id: postId,
        deletedAt: null,
      },
      select: { id: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }
  }
}
