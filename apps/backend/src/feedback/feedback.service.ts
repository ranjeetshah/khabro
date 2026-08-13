import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import {
  FeedbackStatus,
  FeedbackType,
  ModerationAuditAction,
} from '../generated/prisma/enums';

type SafeFeedback = {
  id: string;
  type: FeedbackType;
  message: string;
  status: FeedbackStatus;
  createdAt: Date;
  appVersion?: string | null;
  platform?: string | null;
};

type SafeFeedbackWithUser = SafeFeedback & {
  user: { id: string; name: string | null };
};

@Injectable()
export class FeedbackService {
  constructor(private readonly database: DatabaseService) {}

  async create(userId: string, dto: {
    type: FeedbackType;
    message: string;
    appVersion?: string;
    platform?: string;
  }) {
    const trimmedMessage = dto.message.trim();

    const feedback = await this.database.feedback.create({
      data: {
        userId,
        type: dto.type,
        message: trimmedMessage,
        appVersion: dto.appVersion ?? null,
        platform: dto.platform ?? null,
      },
      select: {
        id: true,
        type: true,
        message: true,
        status: true,
        createdAt: true,
        appVersion: true,
        platform: true,
      },
    });

    return feedback;
  }

  async getMyFeedback(userId: string, page: number, limit: number) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;

    const [items, total] = await Promise.all([
      this.database.feedback.findMany({
        where: { userId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: safeLimit,
        select: {
          id: true,
          type: true,
          message: true,
          status: true,
          createdAt: true,
        },
      }),
      this.database.feedback.count({ where: { userId } }),
    ]);

    return {
      items,
      page: safePage,
      limit: safeLimit,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async getFeedbacks(query: {
    page: number;
    limit: number;
    type?: FeedbackType;
    status?: FeedbackStatus;
  }) {
    const safePage = Math.max(1, query.page || 1);
    const safeLimit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (safePage - 1) * safeLimit;

    const where: any = {};
    if (query.type) where.type = query.type;
    if (query.status) where.status = query.status;

    const [items, total] = await Promise.all([
      this.database.feedback.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: safeLimit,
        select: {
          id: true,
          type: true,
          message: true,
          status: true,
          createdAt: true,
          appVersion: true,
          platform: true,
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      this.database.feedback.count({ where }),
    ]);

    const formatted = items.map((item) => ({
      id: item.id,
      type: item.type,
      message: item.message,
      status: item.status,
      createdAt: item.createdAt,
      appVersion: item.appVersion,
      platform: item.platform,
      user: {
        id: item.user.id,
        name: item.user.name ?? 'Anonymous',
      },
    }));

    return {
      items: formatted,
      page: safePage,
      limit: safeLimit,
      total,
      hasMore: skip + formatted.length < total,
    };
  }

  async getFeedbackDetail(id: string) {
    const feedback = await this.database.feedback.findFirst({
      where: { id },
      select: {
        id: true,
        type: true,
        message: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        appVersion: true,
        platform: true,
        resolvedAt: true,
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!feedback) {
      throw new NotFoundException('Feedback not found');
    }

    return {
      id: feedback.id,
      type: feedback.type,
      message: feedback.message,
      status: feedback.status,
      createdAt: feedback.createdAt,
      updatedAt: feedback.updatedAt,
      appVersion: feedback.appVersion,
      platform: feedback.platform,
      resolvedAt: feedback.resolvedAt,
      user: {
        id: feedback.user.id,
        name: feedback.user.name ?? 'Anonymous',
      },
    };
  }

  async updateStatus(actorId: string, id: string, status: FeedbackStatus) {
    const feedback = await this.database.feedback.findFirst({
      where: { id },
      select: { id: true, status: true },
    });

    if (!feedback) {
      throw new NotFoundException('Feedback not found');
    }

    if (feedback.status === status) {
      throw new BadRequestException('Feedback is already in this status');
    }

    const validTransition = this.isValidTransition(feedback.status, status);
    if (!validTransition) {
      throw new BadRequestException('Invalid status transition');
    }

    const resolvedAt = status === FeedbackStatus.RESOLVED ? new Date() : null;

    await this.database.$transaction(async (tx) => {
      await tx.feedback.update({
        where: { id },
        data: { status, resolvedAt },
      });

      await tx.moderationAuditEvent.create({
        data: {
          feedbackId: id,
          action: ModerationAuditAction.FEEDBACK_STATUS_UPDATED,
          actorId,
        },
      });
    });

    return { id, status };
  }

  private isValidTransition(from: FeedbackStatus, to: FeedbackStatus): boolean {
    if (from === FeedbackStatus.OPEN && to === FeedbackStatus.REVIEWED) return true;
    if (from === FeedbackStatus.REVIEWED && to === FeedbackStatus.RESOLVED) return true;
    return false;
  }
}
