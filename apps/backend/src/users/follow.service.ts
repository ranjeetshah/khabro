import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { NotificationService } from '../notifications/notification.service';
import { NotificationType, UserStatus } from '../generated/prisma/enums';
import { PUBLIC_USER_SELECT } from './public-user.select';

@Injectable()
export class FollowService {
  constructor(
    private readonly database: DatabaseService,
    private readonly notificationService: NotificationService,
  ) {}

  async followUser(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('You cannot follow yourself');
    }

    // Check if target user exists and is not soft-deleted
    const targetUser = await this.database.user.findUnique({
      where: { id: followingId },
      select: { id: true, status: true },
    });

    if (!targetUser || targetUser.status === UserStatus.DELETED) {
      throw new NotFoundException('User not found');
    }

    // Check if follower user exists
    const followerUser = await this.database.user.findUnique({
      where: { id: followerId },
      select: { id: true, name: true },
    });
    if (!followerUser) {
      throw new NotFoundException('Follower user not found');
    }

    // Perform follow and notification creation in a transaction
    return this.database.$transaction(async (tx) => {
      // Find or create follow relation (idempotent)
      let follow = await tx.follow.findUnique({
        where: {
          followerId_followingId: {
            followerId,
            followingId,
          },
        },
      });

      let isNewFollow = false;
      if (!follow) {
        follow = await tx.follow.create({
          data: {
            followerId,
            followingId,
          },
        });
        isNewFollow = true;
      }

      // If it's a new follow, create user followed notification
      if (isNewFollow) {
        const followerName = followerUser.name?.trim() || 'A user';
        await this.notificationService.createNotification(
          tx,
          followingId,
          NotificationType.USER_FOLLOWED,
          'New follower',
          `${followerName} started following you.`,
          'USER',
          followerId,
        );
      }

      // Return follow counts and status
      const [followerCount, followingCount] = await Promise.all([
        tx.follow.count({ where: { followingId } }),
        tx.follow.count({ where: { followerId } }),
      ]);

      return {
        following: true,
        followerCount,
        followingCount,
      };
    });
  }

  async unfollowUser(followerId: string, followingId: string) {
    // Target user must exist (can be deleted/not deleted, unfollow should still succeed)
    const targetUser = await this.database.user.findUnique({
      where: { id: followingId },
      select: { id: true },
    });
    if (!targetUser) {
      throw new NotFoundException('User not found');
    }

    await this.database.$transaction(async (tx) => {
      // Check if exists
      const follow = await tx.follow.findUnique({
        where: {
          followerId_followingId: {
            followerId,
            followingId,
          },
        },
      });

      if (follow) {
        await tx.follow.delete({
          where: {
            followerId_followingId: {
              followerId,
              followingId,
            },
          },
        });
      }
    });

    const [followerCount, followingCount] = await Promise.all([
      this.database.follow.count({ where: { followingId } }),
      this.database.follow.count({ where: { followerId } }),
    ]);

    return {
      following: false,
      followerCount,
      followingCount,
    };
  }

  async getFollowStatus(followerId: string, followingId: string) {
    const targetUser = await this.database.user.findUnique({
      where: { id: followingId },
      select: { id: true, status: true },
    });

    if (!targetUser || targetUser.status === UserStatus.DELETED) {
      throw new NotFoundException('User not found');
    }

    const follow = await this.database.follow.findUnique({
      where: {
        followerId_followingId: {
          followerId,
          followingId,
        },
      },
    });

    const [followerCount, followingCount] = await Promise.all([
      this.database.follow.count({ where: { followingId } }),
      this.database.follow.count({ where: { followerId } }),
    ]);

    return {
      following: !!follow,
      followerCount,
      followingCount,
    };
  }

  async getFollowers(userId: string, page: number, limit: number) {
    const p = Math.max(1, page);
    const l = Math.min(50, Math.max(1, limit));
    const skip = (p - 1) * l;

    const targetUser = await this.database.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });
    if (!targetUser || targetUser.status === UserStatus.DELETED) {
      throw new NotFoundException('User not found');
    }

    const [items, total] = await Promise.all([
      this.database.follow.findMany({
        where: { followingId: userId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: l,
        include: {
          follower: {
            select: PUBLIC_USER_SELECT,
          },
        },
      }),
      this.database.follow.count({
        where: { followingId: userId },
      }),
    ]);

    const formatted = items.map((f) => f.follower);

    return {
      items: formatted,
      page: p,
      limit: l,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async getFollowing(userId: string, page: number, limit: number) {
    const p = Math.max(1, page);
    const l = Math.min(50, Math.max(1, limit));
    const skip = (p - 1) * l;

    const targetUser = await this.database.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true },
    });
    if (!targetUser || targetUser.status === UserStatus.DELETED) {
      throw new NotFoundException('User not found');
    }

    const [items, total] = await Promise.all([
      this.database.follow.findMany({
        where: { followerId: userId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: l,
        include: {
          following: {
            select: PUBLIC_USER_SELECT,
          },
        },
      }),
      this.database.follow.count({
        where: { followerId: userId },
      }),
    ]);

    const formatted = items.map((f) => f.following);

    return {
      items: formatted,
      page: p,
      limit: l,
      total,
      hasMore: skip + items.length < total,
    };
  }
}
