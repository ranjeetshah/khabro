import { Test, TestingModule } from '@nestjs/testing';
import { SuggestionService } from './suggestion.service';
import { DatabaseService } from '../database/database.service';
import { UserStatus } from '../generated/prisma/enums';

describe('SuggestionService', () => {
  let service: SuggestionService;
  let database: DatabaseService;

  const mockDatabaseService = {
    follow: {
      findMany: jest.fn(),
      groupBy: jest.fn(),
    },
    userLocation: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    post: {
      findMany: jest.fn(),
    },
    user: {
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SuggestionService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
      ],
    }).compile();

    service = module.get<SuggestionService>(SuggestionService);
    database = module.get<DatabaseService>(DatabaseService);
  });

  describe('getSuggestions', () => {
    it('should generate deterministic scored suggestions, filtering out self, followed and deleted users', async () => {
      const userId = 'user-current';

      // 1. mock followed list: current user follows 'followed-1'
      mockDatabaseService.follow.findMany
        .mockResolvedValueOnce([{ followingId: 'followed-1' }]) // first call: followed list
        .mockResolvedValueOnce([
          { followerId: 'followed-1', followingId: 'candidate-mutual' },
        ]); // second call: mutual follows

      // 2. mock user location: user is in 'loc-1'
      mockDatabaseService.userLocation.findUnique.mockResolvedValueOnce({
        localityId: 'loc-1',
      });
      mockDatabaseService.userLocation.findMany.mockResolvedValueOnce([
        { userId: 'candidate-locality' },
      ]);

      // 3. mock post activity: 'candidate-active' posted recently
      mockDatabaseService.post.findMany.mockResolvedValueOnce([
        { authorId: 'candidate-active' },
      ]);

      // 4. mock candidate list: all non-deleted active users
      mockDatabaseService.user.findMany.mockResolvedValueOnce([
        { id: 'candidate-mutual', name: 'Mutual User', createdAt: new Date('2026-01-01') },
        { id: 'candidate-locality', name: 'Local User', createdAt: new Date('2026-01-02') },
        { id: 'candidate-active', name: 'Active User', createdAt: new Date('2026-01-03') },
        { id: 'candidate-neutral', name: 'Neutral User', createdAt: new Date('2026-01-04') },
      ]);

      // 5. mock batch counts for target ids
      mockDatabaseService.follow.groupBy
        .mockResolvedValueOnce([{ followingId: 'candidate-mutual', _count: { followerId: 5 } }]) // followers
        .mockResolvedValueOnce([{ followerId: 'candidate-mutual', _count: { followingId: 2 } }]); // following

      const result = await service.getSuggestions(userId, 1, 10);

      // Verify pagination response structure
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
      expect(result.total).toBe(4);
      expect(result.hasMore).toBe(false);

      // Verify ordering by score: Mutual (+100) -> Local (+50) -> Active (+10) -> Neutral (0)
      expect(result.items[0]).toEqual({
        id: 'candidate-mutual',
        name: 'Mutual User',
        followerCount: 5,
        followingCount: 2,
        reason: 'Followed by 1 person you follow',
      });

      expect(result.items[1]).toEqual({
        id: 'candidate-locality',
        name: 'Local User',
        followerCount: 0,
        followingCount: 0,
        reason: 'From your local community',
      });

      expect(result.items[2]).toEqual({
        id: 'candidate-active',
        name: 'Active User',
        followerCount: 0,
        followingCount: 0,
        reason: 'Active in your community',
      });

      expect(result.items[3]).toEqual({
        id: 'candidate-neutral',
        name: 'Neutral User',
        followerCount: 0,
        followingCount: 0,
        reason: undefined,
      });
    });

    it('should paginate results and handle deterministic tie-breaks by createdAt DESC and id DESC', async () => {
      const userId = 'user-current';

      mockDatabaseService.follow.findMany
        .mockResolvedValueOnce([]) // no followed list
        .mockResolvedValueOnce([]); // no mutual list

      mockDatabaseService.userLocation.findUnique.mockResolvedValueOnce(null);
      mockDatabaseService.post.findMany.mockResolvedValueOnce([]);

      // Tie break: all scores are 0, so sorted by createdAt DESC, then id DESC
      mockDatabaseService.user.findMany.mockResolvedValueOnce([
        { id: 'user-a', name: 'User A', createdAt: new Date('2026-01-01T12:00:00Z') },
        { id: 'user-b', name: 'User B', createdAt: new Date('2026-01-01T12:00:00Z') }, // same time, user-b > user-a by id DESC
        { id: 'user-c', name: 'User C', createdAt: new Date('2026-01-02T12:00:00Z') }, // newer time
      ]);

      mockDatabaseService.follow.groupBy
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);

      // Fetch page 1 with limit 2
      const result = await service.getSuggestions(userId, 1, 2);

      expect(result.total).toBe(3);
      expect(result.hasMore).toBe(true);
      expect(result.items.length).toBe(2);

      // Order: user-c (newer), user-b (same time, higher id), user-a
      expect(result.items[0].id).toBe('user-c');
      expect(result.items[1].id).toBe('user-b');
    });

    describe('API Smoke Test Graph Scenario', () => {
      it('should correctly suggest D to A with 2 mutual followers B and C', async () => {
        const userIdA = 'user-A';

        // A follows B and C
        mockDatabaseService.follow.findMany
          .mockResolvedValueOnce([
            { followingId: 'user-B' },
            { followingId: 'user-C' },
          ]) // first call: A's followed list
          .mockResolvedValueOnce([
            { followerId: 'user-B', followingId: 'user-D' },
            { followerId: 'user-C', followingId: 'user-D' },
          ]); // second call: mutual follows (B follows D, C follows D)

        // No locations / recent posts
        mockDatabaseService.userLocation.findUnique.mockResolvedValueOnce(null);
        mockDatabaseService.post.findMany.mockResolvedValueOnce([]);

        // Candidates list (excluding A, B, C)
        mockDatabaseService.user.findMany.mockResolvedValueOnce([
          { id: 'user-D', name: 'User D', createdAt: new Date() },
        ]);

        mockDatabaseService.follow.groupBy
          .mockResolvedValueOnce([{ followingId: 'user-D', _count: { followerId: 2 } }])
          .mockResolvedValueOnce([{ followerId: 'user-D', _count: { followingId: 0 } }]);

        const result = await service.getSuggestions(userIdA, 1, 10);

        expect(result.items.length).toBe(1);
        expect(result.items[0]).toEqual({
          id: 'user-D',
          name: 'User D',
          followerCount: 2,
          followingCount: 0,
          reason: 'Followed by 2 people you follow',
        });
      });
    });
  });
});
