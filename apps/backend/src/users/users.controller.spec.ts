import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { ModerationService } from '../moderation/moderation.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('UsersController', () => {
  let controller: UsersController;

  const mockUser = {
    id: 'user-123',
    phone: '+919876543210',
    name: 'Test User',
    trustScore: 0,
    status: 'ACTIVE',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  };

  const mockUsersService = {
    findMe: jest.fn(),
    findPublic: jest.fn(),
    updateMe: jest.fn(),
    getMyReports: jest.fn(),
    getMyWitnessHistory: jest.fn(),
  };

  const mockModerationService = {
    createPostReport: jest.fn(),
    createUserReport: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
        {
          provide: ModerationService,
          useValue: mockModerationService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<UsersController>(UsersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('GET /users/me', () => {
    it('should return user profile for authenticated user', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.findMe.mockResolvedValue(mockUser);

      const result = await controller.getMe(mockRequest);

      expect(mockUsersService.findMe).toHaveBeenCalledWith('user-123');
      expect(result).toEqual({ user: mockUser });
    });

    it('should use user ID from JWT sub, not from request body', async () => {
      const mockRequest = {
        user: { sub: 'user-123' },
        body: { id: 'attacker-id', userId: 'attacker-id' },
      } as any;
      mockUsersService.findMe.mockResolvedValue(mockUser);

      await controller.getMe(mockRequest);

      expect(mockUsersService.findMe).toHaveBeenCalledWith('user-123');
    });

    it('should throw UnauthorizedException when JWT sub is missing', async () => {
      const mockRequest = { user: {} } as any;

      await expect(controller.getMe(mockRequest)).rejects.toThrow(
        UnauthorizedException,
      );
      expect(mockUsersService.findMe).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException when user no longer exists', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.findMe.mockResolvedValue(null);

      await expect(controller.getMe(mockRequest)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('PATCH /users/me', () => {
    it('should update name and return updated profile', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      const updatedUser = { ...mockUser, name: 'Updated Name' };
      mockUsersService.updateMe.mockResolvedValue(updatedUser);

      const result = await controller.updateMe(mockRequest, {
        name: 'Updated Name',
      });

      expect(mockUsersService.updateMe).toHaveBeenCalledWith('user-123', {
        name: 'Updated Name',
      });
      expect(result).toEqual({ user: updatedUser });
    });

    it('should trim whitespace from name', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.updateMe.mockResolvedValue(mockUser);

      await controller.updateMe(mockRequest, { name: '  Trimmed Name  ' });

      expect(mockUsersService.updateMe).toHaveBeenCalledWith('user-123', {
        name: 'Trimmed Name',
      });
    });

    it('should throw UnauthorizedException when JWT sub is missing', async () => {
      const mockRequest = { user: {} } as any;

      await expect(
        controller.updateMe(mockRequest, { name: 'New Name' }),
      ).rejects.toThrow(UnauthorizedException);
      expect(mockUsersService.updateMe).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException when user no longer exists', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.updateMe.mockResolvedValue(null);

      await expect(
        controller.updateMe(mockRequest, { name: 'New Name' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should use user ID from JWT, not from request body', async () => {
      const mockRequest = {
        user: { sub: 'user-123' },
        body: { id: 'attacker-id' },
      } as any;
      mockUsersService.updateMe.mockResolvedValue(mockUser);

      await controller.updateMe(mockRequest, { name: 'Safe Update' });

      expect(mockUsersService.updateMe).toHaveBeenCalledWith(
        'user-123',
        expect.any(Object),
      );
    });
  });

  describe('GET /users/:id/public', () => {
    it('returns only the safe public user summary', async () => {
      const publicUser = { id: 'user-456', name: 'Public Name' };
      mockUsersService.findPublic.mockResolvedValue(publicUser);

      await expect(controller.getPublic('user-456')).resolves.toEqual({
        user: publicUser,
      });
      expect(mockUsersService.findPublic).toHaveBeenCalledWith('user-456');
    });

    it('returns 404 for an unknown public user', async () => {
      mockUsersService.findPublic.mockResolvedValue(null);
      await expect(controller.getPublic('missing')).rejects.toThrow(
        'Public user not found',
      );
    });
  });

  describe('POST /users/:id/report', () => {
    it('reports a user using the JWT identity and a safe payload', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockModerationService.createUserReport.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      await expect(
        controller.reportUser(mockRequest, 'user-456', {
          reason: 'HARASSMENT',
          description: 'Repeated abuse.',
        } as any),
      ).resolves.toEqual({ id: 'report-1', status: 'OPEN' });

      expect(mockModerationService.createUserReport).toHaveBeenCalledWith(
        'user-123',
        'user-456',
        'HARASSMENT',
        'Repeated abuse.',
      );
    });

    it('never passes a client-provided reporter identity', async () => {
      const mockRequest = {
        user: { sub: 'user-123' },
        body: { reporterId: 'attacker-id', reason: 'SPAM' },
      } as any;
      mockModerationService.createUserReport.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
      });

      await controller.reportUser(mockRequest, 'user-456', { reason: 'SPAM' } as any);

      expect(mockModerationService.createUserReport).toHaveBeenCalledWith(
        'user-123',
        'user-456',
        'SPAM',
        undefined,
      );
    });
  });

  describe('GET /users/me/reports', () => {
    it('delegates to getMyReports using JWT sub', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.getMyReports.mockResolvedValue({ items: [], page: 1, limit: 20, hasNextPage: false });

      const result = await controller.getMyReports(mockRequest, '1', '20');

      expect(mockUsersService.getMyReports).toHaveBeenCalledWith('user-123', 1, 20);
      expect(result).toEqual({ items: [], page: 1, limit: 20, hasNextPage: false });
    });
  });

  describe('GET /users/me/witnesses', () => {
    it('delegates to getMyWitnessHistory using JWT sub', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockUsersService.getMyWitnessHistory.mockResolvedValue({ items: [], page: 1, limit: 20, hasNextPage: false });

      const result = await controller.getMyWitnesses(mockRequest, '1', '20');

      expect(mockUsersService.getMyWitnessHistory).toHaveBeenCalledWith('user-123', 1, 20);
      expect(result).toEqual({ items: [], page: 1, limit: 20, hasNextPage: false });
    });
  });
});
