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
    it('should return user profile when found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findMe('user-123');

      expect(result).toEqual(mockUser);
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
});
