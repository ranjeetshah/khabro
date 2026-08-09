import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { LikesService } from './likes.service';

describe('LikesService', () => {
  let service: LikesService;
  const database = {
    post: { findFirst: jest.fn() },
    like: {
      upsert: jest.fn(),
      deleteMany: jest.fn(),
      count: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [LikesService, { provide: DatabaseService, useValue: database }],
    }).compile();
    service = module.get(LikesService);
    database.post.findFirst.mockResolvedValue({ id: 'post-1' });
    database.like.count.mockResolvedValue(1);
    database.like.findFirst.mockResolvedValue({ id: 'like-1' });
  });

  it('is defined', () => expect(service).toBeDefined());

  it('likes a post using JWT user identity and returns metadata', async () => {
    await expect(service.like('user-1', 'post-1')).resolves.toEqual({
      likeCount: 1,
      likedByMe: true,
    });
    expect(database.like.upsert).toHaveBeenCalledWith({
      where: { userId_postId: { userId: 'user-1', postId: 'post-1' } },
      create: { userId: 'user-1', postId: 'post-1' },
      update: {},
    });
  });

  it('uses an idempotent upsert for duplicate likes', async () => {
    await service.like('user-1', 'post-1');
    await service.like('user-1', 'post-1');
    expect(database.like.upsert).toHaveBeenCalledTimes(2);
  });

  it('unlikes safely, including an already-unliked post', async () => {
    database.like.count.mockResolvedValue(0);
    database.like.findFirst.mockResolvedValue(null);
    await expect(service.unlike('user-1', 'post-1')).resolves.toEqual({
      likeCount: 0,
      likedByMe: false,
    });
    expect(database.like.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', postId: 'post-1' },
    });
  });

  it('rejects missing or deleted posts', async () => {
    database.post.findFirst.mockResolvedValue(null);
    await expect(service.like('user-1', 'missing')).rejects.toThrow(
      NotFoundException,
    );
    await expect(service.unlike('user-1', 'missing')).rejects.toThrow(
      NotFoundException,
    );
    expect(database.like.upsert).not.toHaveBeenCalled();
    expect(database.like.deleteMany).not.toHaveBeenCalled();
  });

  it('returns count and current-user state without exposing like rows', async () => {
    database.like.count.mockResolvedValue(2);
    database.like.findFirst.mockResolvedValue(null);
    await expect(service.getStatus('user-2', 'post-1')).resolves.toEqual({
      likeCount: 2,
      likedByMe: false,
    });
  });
});
