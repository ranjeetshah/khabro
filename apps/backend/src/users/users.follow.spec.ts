import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { FollowService } from './follow.service';
import { DatabaseService } from '../database/database.service';
import { NotificationService } from '../notifications/notification.service';
import { NotificationType, UserStatus } from '../generated/prisma/enums';

describe('FollowService', () => {
  let service: FollowService;
  let database: DatabaseService;
  let notificationService: NotificationService;

  const mockDatabaseService = {
    user: {
      findUnique: jest.fn(),
    },
    follow: {
      findUnique: jest.fn(),
      create: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
      findMany: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockDatabaseService)),
  };

  const mockNotificationService = {
    createNotification: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FollowService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
        {
          provide: NotificationService,
          useValue: mockNotificationService,
        },
      ],
    }).compile();

    service = module.get<FollowService>(FollowService);
    database = module.get<DatabaseService>(DatabaseService);
    notificationService = module.get<NotificationService>(NotificationService);
  });

  describe('followUser', () => {
    it('should follow a user successfully and create notification if new', async () => {
      const followerId = 'user-follower';
      const followingId = 'user-following';

      mockDatabaseService.user.findUnique
        .mockResolvedValueOnce({ id: followingId, status: UserStatus.ACTIVE }) // targetUser
        .mockResolvedValueOnce({ id: followerId, name: 'Follower User' }); // followerUser

      mockDatabaseService.follow.findUnique.mockResolvedValue(null);
      mockDatabaseService.follow.create.mockResolvedValue({ followerId, followingId });
      mockDatabaseService.follow.count
        .mockResolvedValueOnce(5) // followerCount
        .mockResolvedValueOnce(3); // followingCount

      const result = await service.followUser(followerId, followingId);

      expect(result).toEqual({
        following: true,
        followerCount: 5,
        followingCount: 3,
      });

      expect(mockDatabaseService.follow.create).toHaveBeenCalledWith({
        data: { followerId, followingId },
      });

      expect(mockNotificationService.createNotification).toHaveBeenCalledWith(
        expect.anything(),
        followingId,
        NotificationType.USER_FOLLOWED,
        'New follower',
        'Follower User started following you.',
        'USER',
        followerId,
      );
    });

    it('should throw BadRequestException if self-follow', async () => {
      await expect(service.followUser('user-1', 'user-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException if target user does not exist', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValueOnce(null);

      await expect(service.followUser('user-1', 'user-2')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException if target user is deleted', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValueOnce({
        id: 'user-2',
        status: UserStatus.DELETED,
      });

      await expect(service.followUser('user-1', 'user-2')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should be idempotent and not create duplicate follow or duplicate notification', async () => {
      const followerId = 'user-follower';
      const followingId = 'user-following';

      mockDatabaseService.user.findUnique
        .mockResolvedValueOnce({ id: followingId, status: UserStatus.ACTIVE })
        .mockResolvedValueOnce({ id: followerId, name: 'Follower User' });

      mockDatabaseService.follow.findUnique.mockResolvedValue({ followerId, followingId });
      mockDatabaseService.follow.count
        .mockResolvedValueOnce(1)
        .mockResolvedValueOnce(1);

      const result = await service.followUser(followerId, followingId);

      expect(result).toEqual({
        following: true,
        followerCount: 1,
        followingCount: 1,
      });

      expect(mockDatabaseService.follow.create).not.toHaveBeenCalled();
      expect(mockNotificationService.createNotification).not.toHaveBeenCalled();
    });
  });

  describe('unfollowUser', () => {
    it('should unfollow a user and return counts', async () => {
      const followerId = 'user-follower';
      const followingId = 'user-following';

      mockDatabaseService.user.findUnique.mockResolvedValueOnce({ id: followingId });
      mockDatabaseService.follow.findUnique.mockResolvedValue({ followerId, followingId });
      mockDatabaseService.follow.count
        .mockResolvedValueOnce(4)
        .mockResolvedValueOnce(2);

      const result = await service.unfollowUser(followerId, followingId);

      expect(result).toEqual({
        following: false,
        followerCount: 4,
        followingCount: 2,
      });

      expect(mockDatabaseService.follow.delete).toHaveBeenCalled();
    });

    it('should be safe/idempotent if no follow exists', async () => {
      const followerId = 'user-follower';
      const followingId = 'user-following';

      mockDatabaseService.user.findUnique.mockResolvedValueOnce({ id: followingId });
      mockDatabaseService.follow.findUnique.mockResolvedValue(null);
      mockDatabaseService.follow.count
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(0);

      const result = await service.unfollowUser(followerId, followingId);

      expect(result).toEqual({
        following: false,
        followerCount: 0,
        followingCount: 0,
      });

      expect(mockDatabaseService.follow.delete).not.toHaveBeenCalled();
    });
  });

  describe('getFollowStatus', () => {
    it('should return correct follow status', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValueOnce({ id: 'user-2', status: UserStatus.ACTIVE });
      mockDatabaseService.follow.findUnique.mockResolvedValue({ followerId: 'user-1', followingId: 'user-2' });
      mockDatabaseService.follow.count
        .mockResolvedValueOnce(10)
        .mockResolvedValueOnce(5);

      const result = await service.getFollowStatus('user-1', 'user-2');

      expect(result).toEqual({
        following: true,
        followerCount: 10,
        followingCount: 5,
      });
    });
  });

  describe('followers and following lists', () => {
    it('should return paginated followers list with public fields', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValueOnce({ id: 'user-1', status: UserStatus.ACTIVE });
      mockDatabaseService.follow.findMany.mockResolvedValue([
        {
          createdAt: new Date(),
          follower: {
            id: 'follower-1',
            name: 'Follower 1',
          },
        },
      ]);
      mockDatabaseService.follow.count.mockResolvedValue(1);

      const result = await service.getFollowers('user-1', 1, 10);

      expect(result).toEqual({
        items: [{ id: 'follower-1', name: 'Follower 1' }],
        page: 1,
        limit: 10,
        total: 1,
        hasMore: false,
      });
    });

    it('should return paginated following list with public fields', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValueOnce({ id: 'user-1', status: UserStatus.ACTIVE });
      mockDatabaseService.follow.findMany.mockResolvedValue([
        {
          createdAt: new Date(),
          following: {
            id: 'following-1',
            name: 'Following 1',
          },
        },
      ]);
      mockDatabaseService.follow.count.mockResolvedValue(1);

      const result = await service.getFollowing('user-1', 1, 10);

      expect(result).toEqual({
        items: [{ id: 'following-1', name: 'Following 1' }],
        page: 1,
        limit: 10,
        total: 1,
        hasMore: false,
      });
    });
  });
});
