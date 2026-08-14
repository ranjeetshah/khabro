import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { PostsController } from './posts.controller';
import { PostsService } from './posts.service';
import { LikesService } from './likes.service';
import { VerificationHistoryService } from './verification.history.service';
import { VerificationService } from './verification.service';
import { WitnessService } from './witness.service';
import { ModerationService } from '../moderation/moderation.service';
import { CivicComplaintService } from '../civic-complaint/civic-complaint.service';
import { ComplaintService } from '../complaints/complaints.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('PostsController', () => {
  let controller: PostsController;

  const service = {
    create: jest.fn(),
    findMine: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
    search: jest.fn(),
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

  const verificationService = {
    getVerificationStatus: jest.fn(),
  };

  const verificationHistoryService = {
    getHistory: jest.fn(),
  };

  const moderationService = {
    createPostReport: jest.fn(),
    createUserReport: jest.fn(),
  };

  const complaintService = {
    create: jest.fn(),
  };

  const civicComplaintService = {
    getComplaintForPost: jest.fn(),
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
        {
          provide: VerificationService,
          useValue: verificationService,
        },
        {
          provide: VerificationHistoryService,
          useValue: verificationHistoryService,
        },
        {
          provide: ModerationService,
          useValue: moderationService,
        },
        {
          provide: ComplaintService,
          useValue: complaintService,
        },
        {
          provide: CivicComplaintService,
          useValue: civicComplaintService,
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

    const result = await controller.create(authenticatedRequest, {
      content: 'Hello locally',
    });

    expect(service.create).toHaveBeenCalledWith('user-1', {
      content: 'Hello locally',
    });

    expect(result).toEqual({
      id: 'post-1',
      authorId: 'user-1',
      content: 'Hello locally',
    });
  });

  it('delegates search to service with JWT sub and query dto', async () => {
    service.search.mockResolvedValue({
      items: [],
      page: 1,
      limit: 20,
      hasNextPage: false,
    });

    const searchDto = { q: 'road', page: 1, limit: 20 };
    const result = await controller.search(authenticatedRequest, searchDto as any);

    expect(service.search).toHaveBeenCalledWith('user-1', searchDto);
    expect(result).toEqual({
      items: [],
      page: 1,
      limit: 20,
      hasNextPage: false,
    });
  });

  it('gets posts using JWT sub', async () => {
    service.findMine.mockResolvedValue([
      {
        id: 'post-1',
        authorId: 'user-1',
      },
    ]);

    await expect(controller.findMine(authenticatedRequest)).resolves.toEqual([
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
      controller.findOne(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      id: 'post-1',
      authorId: 'user-1',
    });

    expect(service.findOne).toHaveBeenCalledWith('post-1', 'user-1');

    service.findOne.mockResolvedValue(null);

    await expect(
      controller.findOne(authenticatedRequest, 'missing-post'),
    ).resolves.toEqual({
      message: 'Post not found',
    });
  });

  it('deletes using JWT sub', async () => {
    service.delete.mockResolvedValue({
      success: true,
    });

    await expect(
      controller.delete(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      success: true,
    });

    expect(service.delete).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('propagates author ownership rejection', async () => {
    service.delete.mockRejectedValue(new ForbiddenException('Not allowed'));

    await expect(
      controller.delete(authenticatedRequest, 'post-1'),
    ).rejects.toThrow(ForbiddenException);

    expect(service.delete).toHaveBeenCalledWith('user-1', 'post-1');
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
      controller.like(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      like: {
        likeCount: 1,
        likedByMe: true,
      },
    });

    expect(likesService.like).toHaveBeenCalledWith('user-1', 'post-1');

    await expect(
      controller.unlike(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      like: {
        likeCount: 0,
        likedByMe: false,
      },
    });

    expect(likesService.unlike).toHaveBeenCalledWith('user-1', 'post-1');

    await expect(
      controller.getLikes(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      like: {
        likeCount: 1,
        likedByMe: true,
      },
    });

    expect(likesService.getStatus).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('uses JWT identity for witness endpoint', async () => {
    witnessService.witness.mockResolvedValue({
      witnessCount: 1,
      witnessedByMe: true,
    });

    await expect(
      controller.witness(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      witness: {
        witnessCount: 1,
        witnessedByMe: true,
      },
    });

    expect(witnessService.witness).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('uses JWT identity for unwitness endpoint', async () => {
    witnessService.unwitness.mockResolvedValue({
      witnessCount: 0,
      witnessedByMe: false,
    });

    await expect(
      controller.unwitness(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      witness: {
        witnessCount: 0,
        witnessedByMe: false,
      },
    });

    expect(witnessService.unwitness).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('uses JWT identity for witness status endpoint', async () => {
    witnessService.getStatus.mockResolvedValue({
      witnessCount: 2,
      witnessedByMe: false,
    });

    await expect(
      controller.getWitnesses(authenticatedRequest, 'post-1'),
    ).resolves.toEqual({
      witness: {
        witnessCount: 2,
        witnessedByMe: false,
      },
    });

    expect(witnessService.getStatus).toHaveBeenCalledWith('user-1', 'post-1');
  });

  it('returns verification metadata with only safe public fields', async () => {
    verificationService.getVerificationStatus.mockResolvedValue({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 2,
    });

    await expect(controller.getVerification('post-1')).resolves.toEqual({
      status: 'LOCALLY_VERIFIED',
      witnessCount: 2,
    });

    expect(verificationService.getVerificationStatus).toHaveBeenCalledWith(
      'post-1',
    );
  });

  it('reports REPORTED for a freshly created post via the verification endpoint', async () => {
    verificationService.getVerificationStatus.mockResolvedValue({
      status: 'REPORTED',
      witnessCount: 0,
    });

    await expect(controller.getVerification('new-post')).resolves.toEqual({
      status: 'REPORTED',
      witnessCount: 0,
    });
  });

  it('returns verification history with only safe event metadata', async () => {
    verificationHistoryService.getHistory.mockResolvedValue({
      events: [
        {
          type: 'POST_CREATED',
          toStatus: 'REPORTED',
          createdAt: new Date('2026-08-10T00:00:00.000Z'),
        },
        {
          type: 'WITNESS_ADDED',
          createdAt: new Date('2026-08-10T00:00:01.000Z'),
        },
      ],
    });

    await expect(controller.getVerificationHistory('post-1')).resolves.toEqual({
      events: [
        {
          type: 'POST_CREATED',
          toStatus: 'REPORTED',
          createdAt: new Date('2026-08-10T00:00:00.000Z'),
        },
        {
          type: 'WITNESS_ADDED',
          createdAt: new Date('2026-08-10T00:00:01.000Z'),
        },
      ],
    });

    expect(verificationHistoryService.getHistory).toHaveBeenCalledWith(
      'post-1',
    );
  });

  it('requires authentication for the verification history endpoint', async () => {
    expect(
      Reflect.getMetadata('__guards__', PostsController).includes(JwtAuthGuard),
    ).toBe(true);
  });

  it('reports a post using the JWT identity and returns a safe payload', async () => {
    moderationService.createPostReport.mockResolvedValue({
      id: 'report-1',
      status: 'OPEN',
    });

    await expect(
      controller.reportPost(
        authenticatedRequest,
        'post-1',
        { reason: 'SPAM', description: 'Looks like an ad.' } as any,
      ),
    ).resolves.toEqual({ id: 'report-1', status: 'OPEN' });

    expect(moderationService.createPostReport).toHaveBeenCalledWith(
      'user-1',
      'post-1',
      'SPAM',
      'Looks like an ad.',
    );
  });

  it('submits a civic complaint for a post using the JWT identity', async () => {
    complaintService.create.mockResolvedValue({
      id: 'complaint-1',
      status: 'SUBMITTED',
    });

    await expect(
      controller.submitComplaint(
        authenticatedRequest,
        'post-1',
        { description: 'Road is blocked by construction debris.' } as any,
      ),
    ).resolves.toEqual({ id: 'complaint-1', status: 'SUBMITTED' });

    expect(complaintService.create).toHaveBeenCalledWith(
      'user-1',
      'post-1',
      'Road is blocked by construction debris.',
    );
  });

  it('does not pass a client-provided reporter or owner identity', async () => {
    moderationService.createPostReport.mockResolvedValue({
      id: 'report-1',
      status: 'OPEN',
    });
    complaintService.create.mockResolvedValue({
      id: 'complaint-1',
      status: 'SUBMITTED',
    });

    await controller.reportPost(
      authenticatedRequest,
      'post-1',
      { reason: 'SPAM' } as any,
    );
    await controller.submitComplaint(
      authenticatedRequest,
      'post-1',
      { description: 'Road is blocked.' } as any,
    );

    expect(moderationService.createPostReport.mock.calls[0].slice(0, 2)).toEqual(
      ['user-1', 'post-1'],
    );
    expect(complaintService.create.mock.calls[0].slice(0, 2)).toEqual([
      'user-1',
      'post-1',
    ]);
  });
});
