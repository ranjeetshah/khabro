import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtAuthGuard } from './jwt-auth.guard';

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let jwtService: JwtService;
  let configService: ConfigService;

  const mockJwtService = {
    verifyAsync: jest.fn(),
  };

  const mockConfigService = {
    getOrThrow: jest.fn().mockReturnValue('test-secret'),
  };

  function createMockContext(authHeader?: string) {
    const request = {
      headers: {
        authorization: authHeader,
      },
      user: undefined as any,
    };
    return {
      context: {
        switchToHttp: () => ({
          getRequest: () => request,
        }),
      } as ExecutionContext,
      request,
    };
  }

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JwtAuthGuard,
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    guard = module.get<JwtAuthGuard>(JwtAuthGuard);
    jwtService = module.get<JwtService>(JwtService);
    configService = module.get<ConfigService>(ConfigService);
  });

  it('should be defined', () => {
    expect(guard).toBeDefined();
  });

  it('should throw UnauthorizedException when Authorization header is missing', async () => {
    const { context } = createMockContext(undefined);

    await expect(guard.canActivate(context)).rejects.toThrow(
      new UnauthorizedException('Authorization header missing'),
    );
  });

  it('should throw UnauthorizedException when Authorization header has no Bearer prefix', async () => {
    const { context } = createMockContext('Basic token123');

    await expect(guard.canActivate(context)).rejects.toThrow(
      new UnauthorizedException('Invalid authorization format'),
    );
  });

  it('should throw UnauthorizedException when Bearer token is empty (e.g. "Bearer ")', async () => {
    const { context } = createMockContext('Bearer ');

    await expect(guard.canActivate(context)).rejects.toThrow(
      new UnauthorizedException('Invalid authorization format'),
    );
  });

  it('should throw UnauthorizedException when token has too many parts (e.g. "Bearer abc def")', async () => {
    const { context } = createMockContext('Bearer abc def');

    await expect(guard.canActivate(context)).rejects.toThrow(
      new UnauthorizedException('Invalid authorization format'),
    );
  });

  it('should throw UnauthorizedException when token is invalid/expired (jwtService.verifyAsync throws)', async () => {
    mockJwtService.verifyAsync.mockRejectedValue(new Error('jwt expired'));
    const { context } = createMockContext('Bearer invalidtoken');

    await expect(guard.canActivate(context)).rejects.toThrow(
      new UnauthorizedException('Invalid or expired token'),
    );
  });

  it('should pass and set request.user when token is valid', async () => {
    const payload = { sub: '123', email: 'test@example.com' };
    mockJwtService.verifyAsync.mockResolvedValue(payload);
    const { context, request } = createMockContext('Bearer validtoken');

    const result = await guard.canActivate(context);

    expect(result).toBe(true);
    expect(request.user).toEqual(payload);
  });

  it('should call jwtService.verifyAsync with correct token and secret from configService', async () => {
    const payload = { sub: '123' };
    mockJwtService.verifyAsync.mockResolvedValue(payload);
    mockConfigService.getOrThrow.mockReturnValue('test-secret');
    const { context } = createMockContext('Bearer validtoken');

    await guard.canActivate(context);

    expect(configService.getOrThrow).toHaveBeenCalledWith('JWT_SECRET');
    expect(jwtService.verifyAsync).toHaveBeenCalledWith('validtoken', {
      secret: 'test-secret',
    });
  });
});
