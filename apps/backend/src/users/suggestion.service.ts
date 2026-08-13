import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { UserStatus } from '../generated/prisma/enums';

@Injectable()
export class SuggestionService {
  constructor(private readonly database: DatabaseService) {}

  async getSuggestions(userId: string, page: number, limit: number) {
    const p = Math.max(1, page);
    const l = Math.min(50, Math.max(1, limit));
    const skip = (p - 1) * l;

    // 1. Get user IDs that this user is already following
    const follows = await this.database.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });
    const followedIds = follows.map((f) => f.followingId);

    // Exclusion list: self and already followed users
    const excludeIds = [userId, ...followedIds];

    // 2. Query mutual followers
    // Find who the followed users are following
    const mutualFollows = await this.database.follow.findMany({
      where: {
        followerId: { in: followedIds },
        followingId: { notIn: excludeIds },
      },
      select: { followerId: true, followingId: true },
    });

    const mutualCounts = new Map<string, number>();
    for (const mf of mutualFollows) {
      mutualCounts.set(mf.followingId, (mutualCounts.get(mf.followingId) || 0) + 1);
    }

    // 3. Query shared locality/community
    const currentUserLoc = await this.database.userLocation.findUnique({
      where: { userId },
      select: { localityId: true },
    });
    const userLocalityId = currentUserLoc?.localityId;

    let sameLocalityUserIds: string[] = [];
    if (userLocalityId) {
      const locs = await this.database.userLocation.findMany({
        where: {
          localityId: userLocalityId,
          userId: { notIn: excludeIds },
        },
        select: { userId: true },
      });
      sameLocalityUserIds = locs.map((loc) => loc.userId);
    }
    const sameLocalitySet = new Set(sameLocalityUserIds);

    // 4. Query users with recent public posts (within last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const recentPosters = await this.database.post.findMany({
      where: {
        createdAt: { gte: thirtyDaysAgo },
        deletedAt: null,
        authorId: { notIn: excludeIds },
      },
      select: { authorId: true },
      distinct: ['authorId'],
    });
    const activeUserIds = recentPosters.map((p) => p.authorId);
    const activeSet = new Set(activeUserIds);

    // 5. Query candidate users who are active (not deleted) and not excluded
    const candidateUsers = await this.database.user.findMany({
      where: {
        id: { notIn: excludeIds },
        status: { not: UserStatus.DELETED },
      },
      select: {
        id: true,
        name: true,
        createdAt: true,
      },
    });

    // 6. Score candidates
    const scored = candidateUsers.map((u) => {
      let score = 0;
      let reason: string | undefined;

      const mutualCount = mutualCounts.get(u.id) || 0;
      if (mutualCount > 0) {
        score += 100;
        reason = `Followed by ${mutualCount} ${mutualCount === 1 ? 'person' : 'people'} you follow`;
      } else if (sameLocalitySet.has(u.id)) {
        score += 50;
        reason = 'From your local community';
      } else if (activeSet.has(u.id)) {
        score += 10;
        reason = 'Active in your community';
      }

      return {
        user: u,
        score,
        reason,
      };
    });

    // 7. Deterministic sort: score DESC, createdAt DESC, id DESC
    scored.sort((a, b) => {
      if (b.score !== a.score) {
        return b.score - a.score;
      }
      const timeDiff = b.user.createdAt.getTime() - a.user.createdAt.getTime();
      if (timeDiff !== 0) {
        return timeDiff;
      }
      return b.user.id.localeCompare(a.user.id);
    });

    const total = scored.length;
    const paginated = scored.slice(skip, skip + l);

    // 8. Fetch follower & following counts for paginated items in batch to avoid N+1 queries
    const targetIds = paginated.map((p) => p.user.id);

    const followerGroup = await this.database.follow.groupBy({
      by: ['followingId'],
      where: { followingId: { in: targetIds } },
      _count: { followerId: true },
    });

    const followingGroup = await this.database.follow.groupBy({
      by: ['followerId'],
      where: { followerId: { in: targetIds } },
      _count: { followingId: true },
    });

    const followerMap = new Map(
      followerGroup.map((g) => [g.followingId, g._count.followerId])
    );
    const followingMap = new Map(
      followingGroup.map((g) => [g.followerId, g._count.followingId])
    );

    const items = paginated.map((p) => ({
      id: p.user.id,
      name: p.user.name,
      followerCount: followerMap.get(p.user.id) || 0,
      followingCount: followingMap.get(p.user.id) || 0,
      reason: p.reason,
    }));

    return {
      items,
      page: p,
      limit: l,
      total,
      hasMore: skip + paginated.length < total,
    };
  }
}
