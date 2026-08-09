import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import { LikesService } from './likes.service';
import { WitnessService } from './witness.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('PostsController', () => {
  let controller: PostsController;

  const service = {
    create: jest.fn(),
    findMine: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
  };

  const likesService = {
    like: jest.fn(),
    unlike: jest.fn(),
    getStatus: jest.fn(),
  };

  const witnessService = {
    witness: jest.fn(),
    unwitness: jest.fn(),
    getStatus: jest.fn(),
  };

  const authenticatedRequest = {
    user: {
      sub: 'user-1',
    },
  } as any;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [PostsController],
      providers: [
        {
          provide: PostsService,
          useValue: service,
        },
        {
          provide: LikesService,
          useValue: likesService,
        },
        {
          provide: WitnessService,
          useValue: witnessService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: jest.fn().mockReturnValue(true),
      })
      .compile();

    controller = module.get<PostsController>(PostsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('creates using JWT sub and never accepts client identity fields', async () => {
    service.create.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
      content: 'Hello locally',
    });

    const result = await controller.create(
      authenticatedRequest,
      {
        content: 'Hello locally',
      } as any,
    );

    expect(service.create).toHaveBeenCalledWith(
      'user-1',
      'Hello locally',
    );

    expect(result).toEqual({
      id: 'post-1',
      authorId: 'user-1',
      content: 'Hello locally',
    });
  });

  it('gets posts using JWT sub', async () => {
    service.findMine.mockResolvedValue([
      {
        id: 'post-1',
        authorId: 'user-1',
      },
    ]);

    await expect(
      controller.findMine(authenticatedRequest),
    ).resolves.toEqual([
      {
        id: 'post-1',
        authorId: 'user-1',
      },
    ]);

    expect(service.findMine).toHaveBeenCalledWith('user-1');
  });

  it('gets a single post and reports missing posts', async () => {
    service.findOne.mockResolvedValue({
      id: 'post-1',
      authorId: 'user-1',
    });

    await expect(
      controller.findOne(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      id: 'post-1',
      authorId: 'user-1',
    });

    expect(service.findOne).toHaveBeenCalledWith(
      'post-1',
      'user-1',
    );

    service.findOne.mockResolvedValue(null);

    await expect(
      controller.findOne(
        authenticatedRequest,
        'missing-post',
      ),
    ).resolves.toEqual({
      message: 'Post not found',
    });
  });

  it('deletes using JWT sub', async () => {
    service.delete.mockResolvedValue({
      success: true,
    });

    await expect(
      controller.delete(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      success: true,
    });

    expect(service.delete).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });

  it('propagates author ownership rejection', async () => {
    service.delete.mockRejectedValue(
      new ForbiddenException('Not allowed'),
    );

    await expect(
      controller.delete(
        authenticatedRequest,
        'post-1',
      ),
    ).rejects.toThrow(ForbiddenException);

    expect(service.delete).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });

  it('uses JWT identity for like endpoints', async () => {
    likesService.like.mockResolvedValue({
      likeCount: 1,
      likedByMe: true,
    });

    likesService.unlike.mockResolvedValue({
      likeCount: 0,
      likedByMe: false,
    });

    likesService.getStatus.mockResolvedValue({
      likeCount: 1,
      likedByMe: true,
    });

    await expect(
      controller.like(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      like: {
        likeCount: 1,
        likedByMe: true,
      },
    });

    expect(likesService.like).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );

    await expect(
      controller.unlike(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      like: {
        likeCount: 0,
        likedByMe: false,
      },
    });

    expect(likesService.unlike).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );

    await expect(
      controller.getLikes(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      like: {
        likeCount: 1,
        likedByMe: true,
      },
    });

    expect(likesService.getStatus).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });

  it('uses JWT identity for witness endpoint', async () => {
    witnessService.witness.mockResolvedValue({
      witnessCount: 1,
      witnessedByMe: true,
    });

    await expect(
      controller.witness(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      witness: {
        witnessCount: 1,
        witnessedByMe: true,
      },
    });

    expect(witnessService.witness).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });

  it('uses JWT identity for unwitness endpoint', async () => {
    witnessService.unwitness.mockResolvedValue({
      witnessCount: 0,
      witnessedByMe: false,
    });

    await expect(
      controller.unwitness(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      witness: {
        witnessCount: 0,
        witnessedByMe: false,
      },
    });

    expect(witnessService.unwitness).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });

  it('uses JWT identity for witness status endpoint', async () => {
    witnessService.getStatus.mockResolvedValue({
      witnessCount: 2,
      witnessedByMe: false,
    });

    await expect(
      controller.getWitnesses(
        authenticatedRequest,
        'post-1',
      ),
    ).resolves.toEqual({
      witness: {
        witnessCount: 2,
        witnessedByMe: false,
      },
    });

    expect(witnessService.getStatus).toHaveBeenCalledWith(
      'user-1',
      'post-1',
    );
  });
});