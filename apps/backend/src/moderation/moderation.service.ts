import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '../generated/prisma/client';
import {
  ModerationAuditAction,
  PostReportReason,
  ReportStatus,
  UserReportReason,
} from '../generated/prisma/enums';

/**
 * Owns moderation records: content (post) reports, user reports, the report
 * lifecycle, and the audit trail for those actions.
 *
 * Creating a report is a citizen action. Reviewing, resolving, and dismissing
 * are moderator actions: those methods are intentionally backend-only and are
 * NOT exposed through any controller because the project has no moderator
 * role/authentication system yet. Reporting never changes verification state
 * and never hides a post; a report only creates an OPEN record awaiting review.
 */
@Injectable()
export class ModerationService {
  constructor(private readonly database: DatabaseService) {}

  async createPostReport(
    reporterId: string,
    postId: string,
    reason: PostReportReason,
    description?: string,
  ) {
    const post = await this.database.post.findFirst({
      where: { id: postId, deletedAt: null },
      select: { id: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    await this.assertNoOpenDuplicate('postReport', postId, reporterId, reason);

    const report = await this.database.$transaction(async (tx) => {
      const created = await tx.postReport.create({
        data: {
          postId,
          reporterId,
          reason,
          description: this.cleanDescription(description),
        },
        select: { id: true, status: true },
      });

      await tx.moderationAuditEvent.create({
        data: {
          reportId: created.id,
          action: ModerationAuditAction.REPORT_CREATED,
        },
      });

      return created;
    });

    return { id: report.id, status: report.status };
  }

  async createUserReport(
    reporterId: string,
    reportedUserId: string,
    reason: UserReportReason,
    description?: string,
  ) {
    if (reporterId === reportedUserId) {
      throw new BadRequestException('You cannot report yourself');
    }

    const target = await this.database.user.findUnique({
      where: { id: reportedUserId },
      select: { id: true },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    await this.assertNoOpenDuplicate(
      'userReport',
      reportedUserId,
      reporterId,
      reason,
    );

    const report = await this.database.$transaction(async (tx) => {
      const created = await tx.userReport.create({
        data: {
          reportedUserId,
          reporterId,
          reason,
          description: this.cleanDescription(description),
        },
        select: { id: true, status: true },
      });

      await tx.moderationAuditEvent.create({
        data: {
          reportId: created.id,
          action: ModerationAuditAction.REPORT_CREATED,
        },
      });

      return created;
    });

    return { id: report.id, status: report.status };
  }

  /** Moderator-only. Marks an OPEN post report as reviewed. */
  async reviewPostReport(reportId: string) {
    return this.transitionReport(reportId, 'postReport', ReportStatus.REVIEWED);
  }

  /** Moderator-only. Marks an OPEN user report as reviewed. */
  async reviewUserReport(reportId: string) {
    return this.transitionReport(reportId, 'userReport', ReportStatus.REVIEWED);
  }

  /** Moderator-only. Resolves a post report. */
  async resolvePostReport(reportId: string) {
    return this.finalizeReport(reportId, 'postReport', ReportStatus.RESOLVED);
  }

  /** Moderator-only. Resolves a user report. */
  async resolveUserReport(reportId: string) {
    return this.finalizeReport(reportId, 'userReport', ReportStatus.RESOLVED);
  }

  /** Moderator-only. Dismisses a post report. */
  async dismissPostReport(reportId: string) {
    return this.finalizeReport(reportId, 'postReport', ReportStatus.DISMISSED);
  }

  /** Moderator-only. Dismisses a user report. */
  async dismissUserReport(reportId: string) {
    return this.finalizeReport(reportId, 'userReport', ReportStatus.DISMISSED);
  }

  private async transitionReport(
    reportId: string,
    type: 'postReport' | 'userReport',
    to: ReportStatus,
  ) {
    const report = await this.findReport(reportId, type);

    if (report.status !== ReportStatus.OPEN) {
      throw new BadRequestException('Only open reports can be reviewed');
    }

    await this.database.$transaction(async (tx) => {
      await this.updateReportStatus(tx, reportId, type, to);
      await tx.moderationAuditEvent.create({
        data: { reportId, action: ModerationAuditAction.REPORT_REVIEWED },
      });
    });

    return { id: reportId, status: to };
  }

  private async finalizeReport(
    reportId: string,
    type: 'postReport' | 'userReport',
    to: 'RESOLVED' | 'DISMISSED',
  ) {
    const report = await this.findReport(reportId, type);

    if (
      report.status === ReportStatus.RESOLVED ||
      report.status === ReportStatus.DISMISSED
    ) {
      throw new BadRequestException('Report is already finalized');
    }

    const action =
      to === ReportStatus.RESOLVED
        ? ModerationAuditAction.REPORT_RESOLVED
        : ModerationAuditAction.REPORT_DISMISSED;

    await this.database.$transaction(async (tx) => {
      await this.updateReportStatus(tx, reportId, type, to);
      await tx.moderationAuditEvent.create({
        data: { reportId, action },
      });
    });

    return { id: reportId, status: to };
  }

  private async findReport(
    reportId: string,
    type: 'postReport' | 'userReport',
  ) {
    const db = this.database;
    const report =
      type === 'postReport'
        ? await db.postReport.findUnique({
            where: { id: reportId },
            select: { id: true, status: true },
          })
        : await db.userReport.findUnique({
            where: { id: reportId },
            select: { id: true, status: true },
          });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    return report;
  }

  private async updateReportStatus(
    tx: Prisma.TransactionClient,
    reportId: string,
    type: 'postReport' | 'userReport',
    status: ReportStatus,
  ) {
    if (type === 'postReport') {
      await tx.postReport.update({
        where: { id: reportId },
        data: { status },
      });
    } else {
      await tx.userReport.update({
        where: { id: reportId },
        data: { status },
      });
    }
  }

  private async assertNoOpenDuplicate(
    type: 'postReport' | 'userReport',
    targetId: string,
    reporterId: string,
    reason: PostReportReason | UserReportReason,
  ) {
    const db = this.database;
    const existing =
      type === 'postReport'
        ? await db.postReport.findFirst({
            where: {
              postId: targetId,
              reporterId,
              reason,
              status: { in: [ReportStatus.OPEN, ReportStatus.REVIEWED] },
            },
            select: { id: true },
          })
        : await db.userReport.findFirst({
            where: {
              reportedUserId: targetId,
              reporterId,
              reason,
              status: { in: [ReportStatus.OPEN, ReportStatus.REVIEWED] },
            },
            select: { id: true },
          });

    if (existing) {
      throw new ConflictException(
        'You already reported this for the same reason',
      );
    }
  }

  private cleanDescription(description?: string): string | null {
    const cleaned = description?.trim();
    return cleaned && cleaned.length > 0 ? cleaned : null;
  }
}
