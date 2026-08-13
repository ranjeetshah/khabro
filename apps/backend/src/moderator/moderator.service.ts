import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import {
  ReportStatus,
  CivicComplaintStatus,
  FeedbackStatus,
  FeedbackType,
  ModerationAuditAction,
} from '../generated/prisma/enums';

@Injectable()
export class ModeratorService {
  constructor(private readonly database: DatabaseService) {}

  async getDashboardCounts() {
    const [
      openPostReports,
      openUserReports,
      openCommentReports,
      activeCivicComplaints,
      openFeedback,
    ] = await Promise.all([
      this.database.postReport.count({ where: { status: ReportStatus.OPEN } }),
      this.database.userReport.count({ where: { status: ReportStatus.OPEN } }),
      this.database.commentReport.count({ where: { status: ReportStatus.OPEN } }),
      this.database.civicComplaint.count({
        where: {
          status: {
            in: [
              CivicComplaintStatus.SENT,
              CivicComplaintStatus.ACKNOWLEDGED,
              CivicComplaintStatus.IN_PROGRESS,
              CivicComplaintStatus.REOPENED,
            ],
          },
        },
      }),
      this.database.feedback.count({ where: { status: FeedbackStatus.OPEN } }),
    ]);

    return {
      openPostReports,
      openUserReports,
      openCommentReports,
      activeCivicComplaints,
      openFeedback,
    };
  }

  async getReports(query: {
    page: number;
    limit: number;
    type?: string;
    status?: ReportStatus;
  }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const postWhere: any = query.status ? { status: query.status } : {};
    const userWhere: any = query.status ? { status: query.status } : {};
    const commentWhere: any = query.status ? { status: query.status } : {};

    const type = query.type?.toUpperCase();

    if (type === 'POST') {
      const [items, total] = await Promise.all([
        this.database.postReport.findMany({
          where: postWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          skip,
          take: limit,
          include: { post: { select: { id: true, content: true } } },
        }),
        this.database.postReport.count({ where: postWhere }),
      ]);

      const formatted = items.map((r) => this.mapPostReport(r));
      return { items: formatted, page, limit, total, hasMore: skip + items.length < total };
    }

    if (type === 'USER') {
      const [items, total] = await Promise.all([
        this.database.userReport.findMany({
          where: userWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          skip,
          take: limit,
          include: { reportedUser: { select: { id: true, name: true, phone: true } } },
        }),
        this.database.userReport.count({ where: userWhere }),
      ]);

      const formatted = items.map((r) => this.mapUserReport(r));
      return { items: formatted, page, limit, total, hasMore: skip + items.length < total };
    }

    if (type === 'COMMENT') {
      const [items, total] = await Promise.all([
        this.database.commentReport.findMany({
          where: commentWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          skip,
          take: limit,
          include: { comment: { select: { id: true, content: true } } },
        }),
        this.database.commentReport.count({ where: commentWhere }),
      ]);

      const formatted = items.map((r) => this.mapCommentReport(r));
      return { items: formatted, page, limit, total, hasMore: skip + items.length < total };
    }

    // Default: Combined query
    const [allPosts, allUsers, allComments, postTotal, userTotal, commentTotal] =
      await Promise.all([
        this.database.postReport.findMany({
          where: postWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: skip + limit,
          include: { post: { select: { id: true, content: true } } },
        }),
        this.database.userReport.findMany({
          where: userWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: skip + limit,
          include: { reportedUser: { select: { id: true, name: true, phone: true } } },
        }),
        this.database.commentReport.findMany({
          where: commentWhere,
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          take: skip + limit,
          include: { comment: { select: { id: true, content: true } } },
        }),
        this.database.postReport.count({ where: postWhere }),
        this.database.userReport.count({ where: userWhere }),
        this.database.commentReport.count({ where: commentWhere }),
      ]);

    const mappedPosts = allPosts.map((r) => this.mapPostReport(r));
    const mappedUsers = allUsers.map((r) => this.mapUserReport(r));
    const mappedComments = allComments.map((r) => this.mapCommentReport(r));

    const combined = [...mappedPosts, ...mappedUsers, ...mappedComments].sort(
      (a, b) => {
        const timeA = new Date(a.createdAt).getTime();
        const timeB = new Date(b.createdAt).getTime();
        if (timeA !== timeB) return timeB - timeA;
        return b.id.localeCompare(a.id);
      },
    );

    const paginated = combined.slice(skip, skip + limit);
    const total = postTotal + userTotal + commentTotal;

    return {
      items: paginated,
      page,
      limit,
      total,
      hasMore: skip + paginated.length < total,
    };
  }

  async getReportDetail(id: string) {
    const [postReport, userReport, commentReport] = await Promise.all([
      this.database.postReport.findUnique({
        where: { id },
        include: {
          post: {
            select: {
              id: true,
              content: true,
              verificationStatus: true,
              witnesses: { select: { id: true } },
              author: { select: { id: true, name: true } },
            },
          },
        },
      }),
      this.database.userReport.findUnique({
        where: { id },
        include: {
          reportedUser: {
            select: {
              id: true,
              name: true,
              status: true,
              role: true,
              createdAt: true,
            },
          },
        },
      }),
      this.database.commentReport.findUnique({
        where: { id },
        include: {
          comment: {
            select: {
              id: true,
              content: true,
              createdAt: true,
              user: { select: { id: true, name: true } },
              post: { select: { id: true, content: true } },
            },
          },
        },
      }),
    ]);

    if (postReport) {
      return {
        id: postReport.id,
        type: 'POST',
        reason: postReport.reason,
        description: postReport.description,
        status: postReport.status,
        createdAt: postReport.createdAt,
        post: {
          id: postReport.post.id,
          content: postReport.post.content,
          verificationStatus: postReport.post.verificationStatus,
          witnessCount: postReport.post.witnesses.length,
          author: {
            id: postReport.post.author.id,
            name: postReport.post.author.name ?? 'Anonymous',
          },
        },
      };
    }

    if (userReport) {
      return {
        id: userReport.id,
        type: 'USER',
        reason: userReport.reason,
        description: userReport.description,
        status: userReport.status,
        createdAt: userReport.createdAt,
        reportedUser: {
          id: userReport.reportedUser.id,
          name: userReport.reportedUser.name ?? 'Anonymous',
          status: userReport.reportedUser.status,
          role: userReport.reportedUser.role,
        },
      };
    }

    if (commentReport) {
      return {
        id: commentReport.id,
        type: 'COMMENT',
        reason: commentReport.reason,
        description: commentReport.description,
        status: commentReport.status,
        createdAt: commentReport.createdAt,
        comment: {
          id: commentReport.comment.id,
          content: commentReport.comment.content,
          authorName: commentReport.comment.user.name ?? 'Anonymous',
          post: {
            id: commentReport.comment.post.id,
            content: commentReport.comment.post.content,
          },
        },
      };
    }

    throw new NotFoundException('Report not found');
  }

  async updateReportStatus(actorId: string, id: string, status: ReportStatus) {
    const [postReport, userReport, commentReport] = await Promise.all([
      this.database.postReport.findUnique({ where: { id }, select: { id: true, status: true } }),
      this.database.userReport.findUnique({ where: { id }, select: { id: true, status: true } }),
      this.database.commentReport.findUnique({ where: { id }, select: { id: true, status: true } }),
    ]);

    const report = postReport || userReport || commentReport;
    if (!report) {
      throw new NotFoundException('Report not found');
    }

    if (
      report.status === ReportStatus.RESOLVED ||
      report.status === ReportStatus.DISMISSED
    ) {
      throw new BadRequestException('Report is already finalized');
    }

    const type = postReport ? 'POST' : userReport ? 'USER' : 'COMMENT';

    const auditActionMap: Record<ReportStatus, ModerationAuditAction> = {
      [ReportStatus.OPEN]: ModerationAuditAction.REPORT_CREATED,
      [ReportStatus.REVIEWED]: ModerationAuditAction.REPORT_REVIEWED,
      [ReportStatus.RESOLVED]: ModerationAuditAction.REPORT_RESOLVED,
      [ReportStatus.DISMISSED]: ModerationAuditAction.REPORT_DISMISSED,
    };

    const action = auditActionMap[status];

    await this.database.$transaction(async (tx) => {
      if (type === 'POST') {
        await tx.postReport.update({ where: { id }, data: { status } });
      } else if (type === 'USER') {
        await tx.userReport.update({ where: { id }, data: { status } });
      } else {
        await tx.commentReport.update({ where: { id }, data: { status } });
      }

      await tx.moderationAuditEvent.create({
        data: {
          reportId: id,
          action,
          actorId,
        },
      });
    });

    return { id, status };
  }

  async getCivicComplaints(query: { page: number; limit: number; status?: CivicComplaintStatus }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.status) {
      where.status = query.status;
    }

    const [items, total] = await Promise.all([
      this.database.civicComplaint.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: limit,
        select: {
          id: true,
          referenceCode: true,
          status: true,
          witnessCount: true,
          createdAt: true,
          sentAt: true,
          updatedAt: true,
        },
      }),
      this.database.civicComplaint.count({ where }),
    ]);

    return {
      items,
      page,
      limit,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async getCivicComplaintDetail(id: string) {
    const complaint = await this.database.civicComplaint.findFirst({
      where: {
        OR: [{ id }, { referenceCode: id }],
        post: { deletedAt: null },
      },
      select: {
        id: true,
        referenceCode: true,
        status: true,
        witnessCount: true,
        createdAt: true,
        sentAt: true,
        updatedAt: true,
      },
    });

    if (!complaint) {
      throw new NotFoundException('Civic complaint not found');
    }

    const rawHistory = await this.database.civicComplaintStatusHistory.findMany({
      where: { complaintId: complaint.id },
      select: {
        id: true,
        fromStatus: true,
        toStatus: true,
        note: true,
        createdAt: true,
      },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });

    const history = rawHistory.map((h) => ({
      id: h.id,
      fromStatus: h.fromStatus,
      toStatus: h.toStatus,
      note: h.note,
      createdAt: h.createdAt,
    }));

    return {
      ...complaint,
      statusHistory: history,
    };
  }

  async getFeedbacks(query: {
    page: number;
    limit: number;
    type?: FeedbackType;
    status?: FeedbackStatus;
  }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (query.type) where.type = query.type;
    if (query.status) where.status = query.status;

    const [items, total] = await Promise.all([
      this.database.feedback.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: limit,
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
      page,
      limit,
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

  async updateFeedbackStatus(actorId: string, id: string, status: FeedbackStatus) {
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

    const validTransition =
      (feedback.status === FeedbackStatus.OPEN && status === FeedbackStatus.REVIEWED) ||
      (feedback.status === FeedbackStatus.REVIEWED && status === FeedbackStatus.RESOLVED);

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

  private mapPostReport(report: any) {
    return {
      id: report.id,
      type: 'POST',
      reason: report.reason,
      description: report.description,
      status: report.status,
      createdAt: report.createdAt,
      target: {
        id: report.post.id,
        title: report.post.content.length > 80 ? report.post.content.substring(0, 80) + '...' : report.post.content,
      },
    };
  }

  private mapUserReport(report: any) {
    return {
      id: report.id,
      type: 'USER',
      reason: report.reason,
      description: report.description,
      status: report.status,
      createdAt: report.createdAt,
      target: {
        id: report.reportedUser.id,
        title: report.reportedUser.name ?? report.reportedUser.phone,
      },
    };
  }

  private mapCommentReport(report: any) {
    return {
      id: report.id,
      type: 'COMMENT',
      reason: report.reason,
      description: report.description,
      status: report.status,
      createdAt: report.createdAt,
      target: {
        id: report.comment.id,
        title: report.comment.content.length > 80 ? report.comment.content.substring(0, 80) + '...' : report.comment.content,
      },
    };
  }
}
