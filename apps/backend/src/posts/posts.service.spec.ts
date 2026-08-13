import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { VerificationHistoryService } from './verification.history.service';
import { PostsService } from './posts.service';

describe('PostsService', () => {
  let service: PostsService;

  const database = {
    userLocation: { findUnique: jest.fn() },
    post: {
      create: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
    $transaction: jest.fn((callback: (tx: any) => Promise<unknown>) =>
      callback(database),
    ),
  };

  const verificationHistory = {
    recordPostCreated: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PostsService,
        { provide: DatabaseService, useValue: database },
        { provide: VerificationHistoryService, useValue: verificationHistory },
      ],
    }).compile();
    service = module.get(PostsService);
  });

  it('is defined', () => expect(service).toBeDefined());

  it('creates a post using JWT author and stored locality', async () => {
    database.userLocation.findUnique.mockResolvedValue({
      localityId: 'locality-1',
    });
    database.post.create.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
      localityId: 'locality-1',
      content: 'Hello',
    });

    await service.create('user-1', ' Hello ');

    expect(database.userLocation.findUnique).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
      select: { localityId: true },
    });
    expect(database.post.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          authorId: 'user-1',
          localityId: 'locality-1',
          content: 'Hello',
          category: 'GENERAL',
        },
        select: expect.objectContaining({
          author: { select: { id: true, name: true } },
        }),
      }),
    );
  });

  it('records a POST_CREATED event inside the create transaction', async () => {
    database.userLocation.findUnique.mockResolvedValue(null);
    database.post.create.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
      content: 'Hello',
    });

    await service.create('user-1', 'Hello');

    expect(database.$transaction).toHaveBeenCalledTimes(1);
    expect(verificationHistory.recordPostCreated).toHaveBeenCalledWith(
      'post-1',
      database,
    );
  });

  it('creates without locality when the user has no resolved locality', async () => {
    database.userLocation.findUnique.mockResolvedValue(null);
    database.post.create.mockResolvedValue({});

    await service.create('user-1', 'Hello');

    expect(database.post.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ localityId: null }),
      }),
    );
  });

  it('gets my posts newest first and excludes deleted posts', async () => {
    database.post.findMany.mockResolvedValue([]);

    await service.findMine('user-1');

    expect(database.post.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { authorId: 'user-1', deletedAt: null },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    );
  });

  it('gets a non-deleted post', async () => {
    database.post.findFirst.mockResolvedValue({ id: 'post-1' });
    await expect(service.findOne('post-1')).resolves.toEqual({
      id: 'post-1',
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    });
    expect(database.post.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'post-1', deletedAt: null } }),
    );
  });

  it('soft deletes the author-owned post', async () => {
    database.post.findFirst.mockResolvedValue({ authorId: 'user-1' });
    database.post.update.mockResolvedValue({});

    await expect(service.delete('user-1', 'post-1')).resolves.toEqual({
      id: 'post-1',
    });
    expect(database.post.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'post-1' },
        data: { deletedAt: expect.any(Date) },
      }),
    );
  });

  it('rejects deletion by another user', async () => {
    database.post.findFirst.mockResolvedValue({ authorId: 'other-user' });
    await expect(service.delete('user-1', 'post-1')).rejects.toThrow(
      ForbiddenException,
    );
    expect(database.post.update).not.toHaveBeenCalled();
  });

  it('rejects deletion of a missing or deleted post', async () => {
    database.post.findFirst.mockResolvedValue(null);
    await expect(service.delete('user-1', 'post-1')).rejects.toThrow(
      NotFoundException,
    );
  });

  describe('search', () => {
    it('searches posts with keyword, category, verified, recent, and pagination', async () => {
      database.post.findMany.mockResolvedValue([
        { id: 'post-1', content: 'Pothole on Road', category: 'INFRASTRUCTURE', verificationStatus: 'LOCALLY_VERIFIED', createdAt: new Date() },
      ]);

      const res = await service.search('user-1', {
        q: ' road ',
        category: 'INFRASTRUCTURE' as any,
        verified: true,
        recent: true,
        page: 1,
        limit: 20,
      });

      expect(res.items.length).toBe(1);
      expect(database.post.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            deletedAt: null,
            content: { contains: 'road', mode: 'insensitive' },
            category: 'INFRASTRUCTURE',
            verificationStatus: 'LOCALLY_VERIFIED',
            createdAt: expect.objectContaining({ gte: expect.any(Date) }),
          }),
          skip: 0,
          take: 21,
        }),
      );
    });

    it('excludes deleted posts and handles empty query', async () => {
      database.post.findMany.mockResolvedValue([]);

      const res = await service.search('user-1', { q: '   ' });

      expect(res.items).toEqual([]);
      expect(database.post.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { deletedAt: null },
        }),
      );
    });
  });
});
