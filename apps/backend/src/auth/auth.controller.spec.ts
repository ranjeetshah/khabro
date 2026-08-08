import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

describe('AuthController', () => {
  let controller: AuthController;

  const mockUser = {
    id: 'user-123',
    phone: '+919876543210',
    name: 'Test User',
    trustScore: 0,
    status: 'ACTIVE',
  };

  const mockTokenResponse = {
    accessToken: 'mock.jwt.token',
    user: mockUser,
  };

  const mockAuthService = {
    findUserByPhone: jest.fn(),
    findUserById: jest.fn(),
    createUser: jest.fn(),
    generateAccessToken: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: mockAuthService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<AuthController>(AuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('register', () => {
    it('should register a new user and return token response on success', async () => {
      const dto = { phone: '+919876543210', name: 'Test User' };
      mockAuthService.findUserByPhone.mockResolvedValue(null);
      mockAuthService.createUser.mockResolvedValue(mockUser);
      mockAuthService.generateAccessToken.mockResolvedValue(mockTokenResponse);

      const result = await controller.register(dto);

      expect(mockAuthService.findUserByPhone).toHaveBeenCalledWith(dto.phone);
      expect(mockAuthService.createUser).toHaveBeenCalledWith(dto.phone, dto.name);
      expect(mockAuthService.generateAccessToken).toHaveBeenCalledWith(mockUser.id);
      expect(result).toEqual(mockTokenResponse);
    });

    it('should throw ConflictException when user with phone already exists', async () => {
      const dto = { phone: '+919876543210', name: 'Test User' };
      mockAuthService.findUserByPhone.mockResolvedValue(mockUser);

      await expect(controller.register(dto)).rejects.toThrow(ConflictException);
      expect(mockAuthService.findUserByPhone).toHaveBeenCalledWith(dto.phone);
      expect(mockAuthService.createUser).not.toHaveBeenCalled();
    });
  });

  describe('devLogin', () => {
    it('should login user and return token response on success', async () => {
      const dto = { phone: '+919876543210' };
      mockAuthService.findUserByPhone.mockResolvedValue(mockUser);
      mockAuthService.generateAccessToken.mockResolvedValue(mockTokenResponse);

      const result = await controller.devLogin(dto);

      expect(mockAuthService.findUserByPhone).toHaveBeenCalledWith(dto.phone);
      expect(mockAuthService.generateAccessToken).toHaveBeenCalledWith(mockUser.id);
      expect(result).toEqual(mockTokenResponse);
    });

    it('should throw NotFoundException when user is not found', async () => {
      const dto = { phone: '+919876543210' };
      mockAuthService.findUserByPhone.mockResolvedValue(null);

      await expect(controller.devLogin(dto)).rejects.toThrow(NotFoundException);
      expect(mockAuthService.findUserByPhone).toHaveBeenCalledWith(dto.phone);
      expect(mockAuthService.generateAccessToken).not.toHaveBeenCalled();
    });
  });

  describe('getMe', () => {
    it('should return user data when findUserById returns user', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockAuthService.findUserById.mockResolvedValue(mockUser);

      const result = await controller.getMe(mockRequest);

      expect(mockAuthService.findUserById).toHaveBeenCalledWith('user-123');
      expect(result).toEqual({ user: mockUser });
    });

    it('should throw UnauthorizedException when request.user.sub is missing', async () => {
      const mockRequest = { user: {} } as any;

      await expect(controller.getMe(mockRequest)).rejects.toThrow(UnauthorizedException);
      expect(mockAuthService.findUserById).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when findUserById returns null', async () => {
      const mockRequest = { user: { sub: 'user-123' } } as any;
      mockAuthService.findUserById.mockResolvedValue(null);

      await expect(controller.getMe(mockRequest)).rejects.toThrow(NotFoundException);
      expect(mockAuthService.findUserById).toHaveBeenCalledWith('user-123');
    });
  });
});
