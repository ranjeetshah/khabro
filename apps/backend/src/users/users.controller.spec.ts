import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
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
    updateMe: jest.fn(),
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
});
