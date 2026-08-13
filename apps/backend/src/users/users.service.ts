import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { postSelect, toPostResponse } from '../posts/post.select';
import { PUBLIC_USER_SELECT } from './public-user.select';

/** Profile fields safe to expose in API responses. */
const USER_PROFILE_SELECT = {
  id: true,
  phone: true,
  name: true,
  trustScore: true,
  status: true,
  allowCivicComplaintContactSharing: true,
  createdAt: true,
  updatedAt: true,
} as const;

@Injectable()
export class UsersService {
  constructor(private readonly database: DatabaseService) {}

  /**
   * Fetch the authenticated user's profile by ID.
   * Returns null if the user does not exist.
   */
  async findMe(userId: string) {
    const user = await this.database.user.findUnique({
      where: { id: userId },
      select: USER_PROFILE_SELECT,
    });

    if (!user) {
      return null;
    }

    const [
      postCount,
      postReportCount,
      userReportCount,
      witnessCount,
      verifiedContributionCount,
    ] = await Promise.all([
      this.database.post.count({
        where: { authorId: userId, deletedAt: null },
      }),
      this.database.postReport.count({
        where: { reporterId: userId },
      }),
      this.database.userReport.count({
        where: { reporterId: userId },
      }),
      this.database.witness.count({
        where: { userId },
      }),
      this.database.witness.count({
        where: {
          userId,
          post: {
            verificationStatus: 'LOCALLY_VERIFIED',
            deletedAt: null,
          },
        },
      }),
    ]);

    return {
      ...user,
      stats: {
        postCount,
        reportCount: postReportCount + userReportCount,
        witnessCount,
        verifiedContributionCount,
      },
    };
  }

  async findPublic(userId: string) {
    return this.database.user.findUnique({
      where: { id: userId },
      select: PUBLIC_USER_SELECT,
    });
  }

  /**
   * Update the authenticated user's profile.
   * Only accepts explicitly allowed fields.
   */
  async updateMe(
    userId: string,
    data: { name?: string; allowCivicComplaintContactSharing?: boolean },
  ) {
    // Verify user exists first
    const existing = await this.database.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!existing) {
      return null;
    }

    return this.database.user.update({
      where: { id: userId },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.allowCivicComplaintContactSharing !== undefined && {
          allowCivicComplaintContactSharing:
            data.allowCivicComplaintContactSharing,
        }),
      },
      select: USER_PROFILE_SELECT,
    });
  }

  async getMyReports(userId: string, page = 1, limit = 20) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;

    const [postReports, userReports] = await Promise.all([
      this.database.postReport.findMany({
        where: { reporterId: userId },
        orderBy: { createdAt: 'desc' },
        take: safeLimit + 1,
        select: {
          id: true,
          reason: true,
          description: true,
          status: true,
          createdAt: true,
          postId: true,
          post: {
            select: {
              id: true,
              content: true,
            },
          },
        },
      }),
      this.database.userReport.findMany({
        where: { reporterId: userId },
        orderBy: { createdAt: 'desc' },
        take: safeLimit + 1,
        select: {
          id: true,
          reason: true,
          description: true,
          status: true,
          createdAt: true,
          reportedUserId: true,
          reportedUser: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
    ]);

    const combined = [
      ...postReports.map((r) => ({
        id: r.id,
        type: 'POST',
        reason: r.reason,
        description: r.description,
        status: r.status,
        createdAt: r.createdAt,
        targetPostId: r.postId,
        targetContentSnippet: r.post?.content
          ? r.post.content.slice(0, 100)
          : null,
      })),
      ...userReports.map((r) => ({
        id: r.id,
        type: 'USER',
        reason: r.reason,
        description: r.description,
        status: r.status,
        createdAt: r.createdAt,
        targetUserId: r.reportedUserId,
        targetUserName: r.reportedUser?.name ?? null,
      })),
    ].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    const hasNextPage = combined.length > safeLimit;
    const items = hasNextPage
      ? combined.slice(skip, skip + safeLimit)
      : combined.slice(skip);

    return {
      items,
      page: safePage,
      limit: safeLimit,
      hasNextPage,
    };
  }

  async getMyWitnessHistory(userId: string, page = 1, limit = 20) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;

    const witnesses = await this.database.witness.findMany({
      where: {
        userId,
        post: { deletedAt: null },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip,
      take: safeLimit + 1,
      select: {
        id: true,
        createdAt: true,
        post: { select: postSelect(userId) },
      },
    });

    const hasNextPage = witnesses.length > safeLimit;
    const items = (hasNextPage ? witnesses.slice(0, safeLimit) : witnesses).map(
      (w) => ({
        id: w.id,
        createdAt: w.createdAt,
        post: toPostResponse(w.post),
      }),
    );

    return {
      items,
      page: safePage,
      limit: safeLimit,
      hasNextPage,
    };
  }
}
