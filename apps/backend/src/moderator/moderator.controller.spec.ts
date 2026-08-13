import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { ModeratorController } from './moderator.controller';
import { ModeratorService } from './moderator.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ModeratorGuard } from '../auth/guards/moderator.guard';
import { ReportStatus, CivicComplaintStatus, FeedbackStatus } from '../generated/prisma/enums';

describe('ModeratorController', () => {
  let controller: ModeratorController;

  const mockModeratorService = {
    getDashboardCounts: jest.fn(),
    getReports: jest.fn(),
    getReportDetail: jest.fn(),
    updateReportStatus: jest.fn(),
    getCivicComplaints: jest.fn(),
    getCivicComplaintDetail: jest.fn(),
    getFeedbacks: jest.fn(),
    getFeedbackDetail: jest.fn(),
    updateFeedbackStatus: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ModeratorController],
      providers: [
        {
          provide: ModeratorService,
          useValue: mockModeratorService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(ModeratorGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<ModeratorController>(ModeratorController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getDashboard', () => {
    it('returns dashboard counts', async () => {
      mockModeratorService.getDashboardCounts.mockResolvedValue({ counts: 1 });
      const res = await controller.getDashboard();
      expect(res).toEqual({ counts: 1 });
      expect(mockModeratorService.getDashboardCounts).toHaveBeenCalled();
    });
  });

  describe('getReports', () => {
    it('calls getReports on service with queries', async () => {
      mockModeratorService.getReports.mockResolvedValue({ items: [] });
      const query = { page: 1, limit: 10, type: 'POST', status: ReportStatus.OPEN };
      const res = await controller.getReports(query);
      expect(res).toEqual({ items: [] });
      expect(mockModeratorService.getReports).toHaveBeenCalledWith(query);
    });
  });

  describe('updateReportStatus', () => {
    it('calls updateReportStatus with sub and payload', async () => {
      mockModeratorService.updateReportStatus.mockResolvedValue({ success: true });
      const req = { user: { sub: 'moderator-1' } } as any;
      const res = await controller.updateReportStatus(req, 'r-1', { status: ReportStatus.REVIEWED });
      expect(res).toEqual({ success: true });
      expect(mockModeratorService.updateReportStatus).toHaveBeenCalledWith(
        'moderator-1',
        'r-1',
        ReportStatus.REVIEWED,
      );
    });
  });

  describe('getFeedbacks', () => {
    it('calls getFeedbacks with query', async () => {
      mockModeratorService.getFeedbacks.mockResolvedValue({ items: [] });
      const query = { page: 1, limit: 10, type: 'BUG', status: FeedbackStatus.OPEN };
      const res = await controller.getFeedbacks(query);
      expect(res).toEqual({ items: [] });
      expect(mockModeratorService.getFeedbacks).toHaveBeenCalledWith(query);
    });
  });

  describe('getFeedbackDetail', () => {
    it('calls getFeedbackDetail with id', async () => {
      mockModeratorService.getFeedbackDetail.mockResolvedValue({ id: 'f-1' });
      const res = await controller.getFeedbackDetail('f-1');
      expect(res).toEqual({ id: 'f-1' });
      expect(mockModeratorService.getFeedbackDetail).toHaveBeenCalledWith('f-1');
    });
  });

  describe('updateFeedbackStatus', () => {
    it('calls updateFeedbackStatus with sub and payload', async () => {
      mockModeratorService.updateFeedbackStatus.mockResolvedValue({ success: true });
      const req = { user: { sub: 'moderator-1' } } as any;
      const res = await controller.updateFeedbackStatus(req, 'f-1', { status: FeedbackStatus.REVIEWED });
      expect(res).toEqual({ success: true });
      expect(mockModeratorService.updateFeedbackStatus).toHaveBeenCalledWith(
        'moderator-1',
        'f-1',
        FeedbackStatus.REVIEWED,
      );
    });
  });
});
