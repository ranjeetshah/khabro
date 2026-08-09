import { ForbiddenException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';

describe('PostsController', () => {
  let controller: PostsController;
  const service = {
    create: jest.fn(),
    findMine: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PostsController],
      providers: [{ provide: PostsService, useValue: service }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();
    controller = module.get(PostsController);
  });

  it('creates using JWT sub and never accepts client identity fields', async () => {
    service.create.mockResolvedValue({ id: 'post-1' });
    await controller.create(
      { user: { sub: 'user-1' }, body: { authorId: 'attacker', localityId: 'other' } } as any,
      { content: 'Hello' },
    );
    expect(service.create).toHaveBeenCalledWith('user-1', 'Hello');
  });

  it('gets posts using JWT sub', async () => {
    service.findMine.mockResolvedValue([]);
    await expect(controller.getMine({ user: { sub: 'user-1' } } as any)).resolves.toEqual({ posts: [] });
    expect(service.findMine).toHaveBeenCalledWith('user-1');
  });

  it('gets a single post and reports missing posts', async () => {
    service.findOne.mockResolvedValue({ id: 'post-1' });
    await expect(controller.getOne('post-1')).resolves.toEqual({ post: { id: 'post-1' } });
    service.findOne.mockResolvedValue(null);
    await expect(controller.getOne('post-1')).rejects.toThrow(NotFoundException);
  });

  it('deletes using JWT sub', async () => {
    service.delete.mockResolvedValue({ id: 'post-1' });
    await expect(controller.remove({ user: { sub: 'user-1' } } as any, 'post-1')).resolves.toEqual({ post: { id: 'post-1' } });
    expect(service.delete).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('propagates author ownership rejection', async () => {
    service.delete.mockRejectedValue(new ForbiddenException());
    await expect(controller.remove({ user: { sub: 'user-1' } } as any, 'post-1')).rejects.toThrow(ForbiddenException);
  });

  it('rejects requests without a JWT subject', async () => {
    await expect(controller.create({ user: {} } as any, { content: 'Hello' })).rejects.toThrow(UnauthorizedException);
    await expect(controller.getMine({ user: {} } as any)).rejects.toThrow(UnauthorizedException);
    await expect(controller.remove({ user: {} } as any, 'post-1')).rejects.toThrow(UnauthorizedException);
  });
});
