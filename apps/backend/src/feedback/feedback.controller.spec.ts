import { Test, TestingModule } from '@nestjs/testing';
import { FeedbackController } from './feedback.controller';
import { FeedbackService } from './feedback.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

describe('FeedbackController', () => {
  let controller: FeedbackController;

  const feedbackService = {
    create: jest.fn(),
    getMyFeedback: jest.fn(),
  };

  const authenticatedRequest = {
    user: {
      sub: 'user-1',
    },
  } as any;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FeedbackController],
      providers: [
        { provide: FeedbackService, useValue: feedbackService },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: jest.fn().mockReturnValue(true),
      })
      .compile();

    controller = module.get(FeedbackController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('creates feedback using JWT sub and never accepts client identity fields', async () => {
    feedbackService.create.mockResolvedValue({
      id: 'f-1',
      type: 'BUG',
      status: 'OPEN',
      createdAt: new Date(),
    });

    const result = await controller.create(
      authenticatedRequest,
      {
        type: 'BUG',
        message: 'Bug here',
      } as any,
    );

    expect(feedbackService.create).toHaveBeenCalledWith('user-1', {
      type: 'BUG',
      message: 'Bug here',
      appVersion: undefined,
      platform: undefined,
    });
    expect(result).toEqual({
      id: 'f-1',
      type: 'BUG',
      status: 'OPEN',
      createdAt: expect.any(Date),
    });
  });

  it('returns only the authenticated users feedback', async () => {
    feedbackService.getMyFeedback.mockResolvedValue({
      items: [],
      page: 1,
      limit: 20,
      total: 0,
      hasMore: false,
    });

    const result = await controller.getMine(
      authenticatedRequest,
      { page: 1, limit: 20 } as any,
    );

    expect(feedbackService.getMyFeedback).toHaveBeenCalledWith('user-1', 1, 20);
    expect(result.items).toEqual([]);
  });
});
