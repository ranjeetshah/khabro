import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FeedController } from './feed.controller';
import { FeedService } from './feed.service';
import { FeedQueryDto } from './dto/feed-query.dto';

describe('FeedController', () => {
  let controller: FeedController;
  const service = { getFeed: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FeedController],
      providers: [{ provide: FeedService, useValue: service }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();
    controller = module.get(FeedController);
  });

  it('uses JWT user ID and ignores client locality fields', async () => {
    service.getFeed.mockResolvedValue({ items: [], nextCursor: null });
    const query = Object.assign(new FeedQueryDto(), {
      limit: 20,
      cursor: undefined,
      localityId: 'attacker-locality',
    });
    await controller.getFeed({ user: { sub: 'user-1' } } as any, query);
    expect(service.getFeed).toHaveBeenCalledWith('user-1', 20, undefined);
  });

  it('rejects a request without JWT subject', async () => {
    await expect(
      controller.getFeed({ user: {} } as any, new FeedQueryDto()),
    ).rejects.toThrow(UnauthorizedException);
    expect(service.getFeed).not.toHaveBeenCalled();
  });
});
