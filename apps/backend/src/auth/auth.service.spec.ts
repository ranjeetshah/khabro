import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { DatabaseService } from '../database/database.service';

describe('AuthService', () => {
  let service: AuthService;

  const mockUser = {
    id: 'user-123',
    phone: '+919876543210',
    name: 'Test User',
    trustScore: 0,
    status: 'ACTIVE',
  };

  const mockDatabaseService = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  };

  const mockJwtService = {
    signAsync: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findUserByPhone', () => {
    it('should return user when found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findUserByPhone('+919876543210');

      expect(result).toEqual(mockUser);
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { phone: '+919876543210' },
        select: expect.any(Object),
      });
    });

    it('should return null when not found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      const result = await service.findUserByPhone('+919876543210');

      expect(result).toBeNull();
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { phone: '+919876543210' },
        select: expect.any(Object),
      });
    });
  });

  describe('findUserById', () => {
    it('should return user when found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findUserById('user-123');

      expect(result).toEqual(mockUser);
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        select: expect.any(Object),
      });
    });

    it('should return null when not found', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      const result = await service.findUserById('user-123');

      expect(result).toBeNull();
      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        select: expect.any(Object),
      });
    });
  });

  describe('createUser', () => {
    it('should create and return a new user on success', async () => {
      mockDatabaseService.user.create.mockResolvedValue(mockUser);

      const result = await service.createUser('+919876543210', 'Test User');

      expect(result).toEqual(mockUser);
      expect(mockDatabaseService.user.create).toHaveBeenCalledWith({
        data: { phone: '+919876543210', name: 'Test User' },
        select: expect.any(Object),
      });
    });

    it('should throw ConflictException on duplicate phone (Prisma P2002 error)', async () => {
      const p2002Error = { code: 'P2002' };
      mockDatabaseService.user.create.mockRejectedValue(p2002Error);

      await expect(
        service.createUser('+919876543210', 'Test User'),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('generateAccessToken', () => {
    it('should generate access token for active user and verify payload has only sub', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(mockUser);
      mockJwtService.signAsync.mockResolvedValue('token-123');

      const result = await service.generateAccessToken('user-123');

      expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
        where: { id: 'user-123' },
        select: expect.any(Object),
      });
      expect(mockJwtService.signAsync).toHaveBeenCalledWith({ sub: 'user-123' });
      expect(result).toEqual({
        accessToken: 'token-123',
        user: {
          id: mockUser.id,
          phone: mockUser.phone,
          name: mockUser.name,
          trustScore: mockUser.trustScore,
          status: mockUser.status,
        },
      });
    });

    it('should throw NotFoundException for non-existent user', async () => {
      mockDatabaseService.user.findUnique.mockResolvedValue(null);

      await expect(service.generateAccessToken('user-123')).rejects.toThrow(
        NotFoundException,
      );
      expect(mockJwtService.signAsync).not.toHaveBeenCalled();
    });

    it('should throw UnauthorizedException for SUSPENDED user', async () => {
      const suspendedUser = { ...mockUser, status: 'SUSPENDED' };
      mockDatabaseService.user.findUnique.mockResolvedValue(suspendedUser);

      await expect(service.generateAccessToken('user-123')).rejects.toThrow(
        UnauthorizedException,
      );
      expect(mockJwtService.signAsync).not.toHaveBeenCalled();
    });
  });
});
