import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { FeedService } from './feed.service';

describe('FeedService', () => {
  let service: FeedService;
  const database = {
    userLocation: { findUnique: jest.fn() },
    post: { findMany: jest.fn() },
  };

  const post = (id: string, createdAt: string, localityId = 'locality-a') => ({
    id,
    authorId: 'author-1',
    localityId,
    content: id,
    createdAt: new Date(createdAt),
    updatedAt: new Date(createdAt),
  });

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [FeedService, { provide: DatabaseService, useValue: database }],
    }).compile();
    service = module.get(FeedService);
  });

  it('is defined', () => expect(service).toBeDefined());

  it('returns empty when the user has no location or locality', async () => {
    database.userLocation.findUnique.mockResolvedValueOnce(null);
    await expect(service.getFeed('user-1', 20)).resolves.toEqual({ items: [], nextCursor: null });
    database.userLocation.findUnique.mockResolvedValueOnce({ localityId: null });
    await expect(service.getFeed('user-1', 20)).resolves.toEqual({ items: [], nextCursor: null });
    expect(database.post.findMany).not.toHaveBeenCalled();
  });

  it('filters by the authenticated user locality and excludes deleted posts', async () => {
    database.userLocation.findUnique.mockResolvedValue({ localityId: 'locality-a' });
    database.post.findMany.mockResolvedValue([post('a1', '2026-08-09T08:00:00.000Z')]);
    await service.getFeed('user-1', 20);
    expect(database.post.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { localityId: 'locality-a', deletedAt: null },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 21,
      }),
    );
  });

  it('returns a cursor when there is another page', async () => {
    database.userLocation.findUnique.mockResolvedValue({ localityId: 'locality-a' });
    database.post.findMany.mockResolvedValue([
      post('new', '2026-08-09T09:00:00.000Z'),
      post('old', '2026-08-09T08:00:00.000Z'),
      post('extra', '2026-08-09T07:00:00.000Z'),
    ]);
    const first = await service.getFeed('user-1', 2);
    expect(first.items).toHaveLength(2);
    expect(first.nextCursor).toEqual(expect.any(String));

    database.post.findMany.mockResolvedValue([post('last', '2026-08-09T06:00:00.000Z')]);
    const second = await service.getFeed('user-1', 2, first.nextCursor!);
    expect(second.nextCursor).toBeNull();
    expect(database.post.findMany).toHaveBeenLastCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          localityId: 'locality-a',
          deletedAt: null,
          OR: expect.any(Array),
        }),
      }),
    );
  });

  it('rejects an invalid cursor', async () => {
    database.userLocation.findUnique.mockResolvedValue({ localityId: 'locality-a' });
    await expect(service.getFeed('user-1', 20, 'bad')).rejects.toThrow('Invalid feed cursor');
  });
});
