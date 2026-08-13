import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../../database/database.service';
import { ModeratorGuard } from './moderator.guard';
import { UserRole } from '../../generated/prisma/enums';

describe('ModeratorGuard', () => {
  let guard: ModeratorGuard;

  const mockDatabaseService = {
    user: {
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ModeratorGuard,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
      ],
    }).compile();

    guard = module.get<ModeratorGuard>(ModeratorGuard);
  });

  const createMockContext = (user: any): ExecutionContext => {
    return {
      switchToHttp: () => ({
        getRequest: () => ({
          user,
        }),
      }),
    } as any;
  };

  it('allows access for MODERATOR role', async () => {
    mockDatabaseService.user.findUnique.mockResolvedValue({ role: UserRole.MODERATOR });
    const context = createMockContext({ sub: 'user-mod' });
    const canActivate = await guard.canActivate(context);
    expect(canActivate).toBe(true);
    expect(mockDatabaseService.user.findUnique).toHaveBeenCalledWith({
      where: { id: 'user-mod' },
      select: { role: true },
    });
  });

  it('denies access (throws ForbiddenException) for CITIZEN role', async () => {
    mockDatabaseService.user.findUnique.mockResolvedValue({ role: UserRole.CITIZEN });
    const context = createMockContext({ sub: 'user-cit' });
    await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
  });

  it('denies access if payload missing sub', async () => {
    const context = createMockContext({});
    await expect(guard.canActivate(context)).rejects.toThrow(ForbiddenException);
  });
});
