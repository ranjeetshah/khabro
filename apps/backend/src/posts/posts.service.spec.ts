import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { PostBackground, PostCategory, PostMediaType } from '../generated/prisma/enums';
import { VerificationHistoryService } from './verification.history.service';
import { PostsService } from './posts.service';

describe('PostsService', () => {
  let service: PostsService;

  const database = {
    userLocation: { findUnique: jest.fn() },
    postMedia: { findMany: jest.fn(), update: jest.fn() },
    post: {
      create: jest.fn(),
      findUnique: jest.fn(),
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
    database.post.findUnique.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
      localityId: 'locality-1',
      content: 'Hello',
      category: PostCategory.GENERAL,
      background: PostBackground.DEFAULT,
      media: [],
    });

    await service.create('user-1', { content: ' Hello ' });

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
          category: PostCategory.GENERAL,
          background: PostBackground.DEFAULT,
          linkUrl: null,
        },
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
    database.post.findUnique.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
      content: 'Hello',
      media: [],
    });

    await service.create('user-1', { content: 'Hello' });

    expect(database.$transaction).toHaveBeenCalledTimes(1);
    expect(verificationHistory.recordPostCreated).toHaveBeenCalledWith(
      'post-1',
      database,
    );
  });

  it('allows text-only posts with custom background', async () => {
    database.userLocation.findUnique.mockResolvedValue(null);
    database.post.create.mockResolvedValue({ id: 'post-1' });
    database.post.findUnique.mockResolvedValue({ id: 'post-1', background: PostBackground.RED, media: [] });

    await service.create('user-1', { content: 'Alert!', background: PostBackground.RED });

    expect(database.post.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ background: PostBackground.RED }),
      }),
    );
  });

  it('forces background DEFAULT when post has media attached', async () => {
    database.userLocation.findUnique.mockResolvedValue(null);
    database.postMedia.findMany.mockResolvedValue([
      { id: 'media-1', createdById: 'user-1', type: PostMediaType.IMAGE },
    ]);
    database.post.create.mockResolvedValue({ id: 'post-1' });
    database.post.findUnique.mockResolvedValue({ id: 'post-1', background: PostBackground.DEFAULT, media: [] });

    await service.create('user-1', {
      content: 'Image post',
      background: PostBackground.RED,
      mediaIds: ['media-1'],
    });

    expect(database.post.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ background: PostBackground.DEFAULT }),
      }),
    );
  });

  it('rejects post creation if attached media belongs to another user', async () => {
    database.postMedia.findMany.mockResolvedValue([
      { id: 'media-1', createdById: 'other-user', type: PostMediaType.IMAGE },
    ]);

    await expect(
      service.create('user-1', { content: 'Image post', mediaIds: ['media-1'] }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('rejects post creation if media exceeds 4 images', async () => {
    database.postMedia.findMany.mockResolvedValue([
      { id: 'm1', createdById: 'user-1', type: PostMediaType.IMAGE },
      { id: 'm2', createdById: 'user-1', type: PostMediaType.IMAGE },
      { id: 'm3', createdById: 'user-1', type: PostMediaType.IMAGE },
      { id: 'm4', createdById: 'user-1', type: PostMediaType.IMAGE },
      { id: 'm5', createdById: 'user-1', type: PostMediaType.IMAGE },
    ]);

    await expect(
      service.create('user-1', {
        content: 'Too many images',
        mediaIds: ['m1', 'm2', 'm3', 'm4', 'm5'],
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects post creation with unsafe linkUrl', async () => {
    await expect(
      service.create('user-1', {
        content: 'Malicious link',
        linkUrl: 'javascript:alert(1)',
      }),
    ).rejects.toThrow(BadRequestException);
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
      background: 'DEFAULT',
      linkUrl: null,
      media: [],
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    });
  });

  it('soft deletes the author-owned post', async () => {
    database.post.findFirst.mockResolvedValue({ authorId: 'user-1' });
    database.post.update.mockResolvedValue({});

    await expect(service.delete('user-1', 'post-1')).resolves.toEqual({
      id: 'post-1',
    });
  });
});
