import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { DatabaseService } from '../database/database.service';

describe('UsersService', () => {
  let service: UsersService;

  const mockUser = {
    id: 'user-123',
    phone: '+919876543210',
    name: 'Test User',
    trustScore: 0,
    status: 'ACTIVE',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  };

  const mockDatabaseService = {
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    post: {
      count: jest.fn(),
    },
    postReport: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
    userReport: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
    witness: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findMe', () => {
    it('should return user profile with contribution stats when found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);
      mockDatabaseService.post.count.mockResolvedValue(5);
      mockDatabaseService.postReport.count.mockResolvedValue(2);
      mockDatabaseService.userReport.count.mockResolvedValue(1);
      mockDatabaseService.witness.count.mockResolvedValue(3);

      const result = await service.findMe('user-123');

      expect(result).toEqual({
        ...mockUser,
        stats: {
          postCount: 5,
          reportCount: 3,
          witnessCount: 3,
          verifiedContributionCount: 3,
        },
      });
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        select: expect.objectContaining({
          id: true,
          phone: true,
          name: true,
          trustScore: true,
          status: true,
          createdAt: true,
          updatedAt: true,
        }),
      });
    });

    it('should return null when user not found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      const result = await service.findMe('nonexistent-user');

      expect(result).toBeNull();
    });

    it('should include createdAt and updatedAt in select', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      await service.findMe('user-123');

      const selectArg =
        mockDatabaseService.user.findUnique.mock.calls[0][0].select;
      expect(selectArg.createdAt).toBe(true);
      expect(selectArg.updatedAt).toBe(true);
    });
  });

  describe('updateMe', () => {
    it('should update name and return updated user', async () => {
      const updatedUser = { ...mockUser, name: 'New Name' };
      mockDatabaseService.user.findUnique.mockResolvedValue({ id: 'user-123' });
      mockDatabaseService.user.update.mockResolvedValue(updatedUser);

      const result = await service.updateMe('user-123', { name: 'New Name' });

      expect(result).toEqual(updatedUser);
      expect(mockDatabaseService.user.update).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        data: { name: 'New Name' },
        select: expect.objectContaining({
          id: true,
          phone: true,
          name: true,
          trustScore: true,
          status: true,
          createdAt: true,
          updatedAt: true,
        }),
      });
    });

    it('should return null when user does not exist', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      const result = await service.updateMe('nonexistent-user', {
        name: 'New Name',
      });

      expect(result).toBeNull();
      expect(mockDatabaseService.user.update).not.toHaveBeenCalled();
    });

    it('should not include name in data when name is undefined', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue({ id: 'user-123' });
      mockDatabaseService.user.update.mockResolvedValue(mockUser);

      await service.updateMe('user-123', {});

      const updateArg = mockDatabaseService.user.update.mock.calls[0][0];
      expect(updateArg.data).toEqual({});
    });
  });

  describe('findPublic', () => {
    it('selects only id and name', async () => {
      const publicUser = { id: 'user-123', name: 'Test User' };
      mockDatabaseService.user.findUnique.mockResolvedValue(publicUser);

      await expect(service.findPublic('user-123')).resolves.toEqual(publicUser);
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        select: { id: true, name: true },
      });
      expect(JSON.stringify(publicUser)).not.toMatch(
        /phone|trustScore|status|location|latitude|longitude/,
      );
    });
  });

  describe('getMyReports', () => {
    it('returns combined paginated post and user reports for user', async () => {
      mockDatabaseService.postReport.findMany.mockResolvedValue([
        { id: 'pr1', reason: 'SPAM', description: 'spammy', status: 'OPEN', createdAt: new Date('2026-08-13T10:00:00Z'), postId: 'p1', post: { content: 'Post content' } },
      ]);
      mockDatabaseService.userReport.findMany.mockResolvedValue([]);

      const result = await service.getMyReports('user-123', 1, 20);

      expect(result.items.length).toBe(1);
      expect(result.items[0]).toEqual(
        expect.objectContaining({
          id: 'pr1',
          type: 'POST',
          reason: 'SPAM',
        }),
      );
    });
  });

  describe('getMyWitnessHistory', () => {
    it('returns paginated witness history for user', async () => {
      mockDatabaseService.witness.findMany.mockResolvedValue([
        { id: 'w1', createdAt: new Date('2026-08-13T10:00:00Z'), post: { id: 'p1', authorId: 'u2', content: 'Witnessed post' } },
      ]);

      const result = await service.getMyWitnessHistory('user-123', 1, 20);

      expect(result.items.length).toBe(1);
      expect(result.items[0].id).toBe('w1');
      expect(result.items[0].post.id).toBe('p1');
    });
  });
});
