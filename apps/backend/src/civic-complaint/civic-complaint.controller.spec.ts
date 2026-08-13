import { Test, TestingModule } from '@nestjs/testing';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CivicComplaintController } from './civic-complaint.controller';
import { CivicComplaintService } from './civic-complaint.service';
import { CivicComplaintStatus } from '../generated/prisma/enums';

describe('CivicComplaintController', () => {
  let controller: CivicComplaintController;
  let service: any;

  const authenticatedRequest = {
    user: {
      sub: 'user-1',
      role: 'CITIZEN',
    },
  } as any;

  const moderatorRequest = {
    user: {
      sub: 'mod-1',
      role: 'MODERATOR',
    },
  } as any;

  beforeEach(async () => {
    service = {
      getPublicComplaintById: jest.fn(),
      getStatusHistory: jest.fn(),
      updateStatusByAuthority: jest.fn(),
      confirmResolutionByCitizen: jest.fn(),
      reopenComplaintByCitizen: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [CivicComplaintController],
      providers: [
        { provide: CivicComplaintService, useValue: service },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: jest.fn().mockReturnValue(true) })
      .compile();

    controller = module.get<CivicComplaintController>(CivicComplaintController);
  });

  it('gets public complaint by id without sensitive fields', async () => {
    service.getPublicComplaintById.mockResolvedValue({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.SENT,
    });

    const result = await controller.getComplaint('comp-1');

    expect(result).toEqual({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.SENT,
    });
    expect(service.getPublicComplaintById).toHaveBeenCalledWith('comp-1');
  });

  it('gets status history timeline', async () => {
    service.getStatusHistory.mockResolvedValue([
      {
        fromStatus: CivicComplaintStatus.SENT,
        toStatus: CivicComplaintStatus.ACKNOWLEDGED,
        note: 'Assigned',
        createdAt: new Date(),
      },
    ]);

    const result = await controller.getHistory('comp-1');

    expect(result.length).toBe(1);
    expect(service.getStatusHistory).toHaveBeenCalledWith('comp-1');
  });

  it('updates status by authority using JWT actor sub and role', async () => {
    service.updateStatusByAuthority.mockResolvedValue({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.ACKNOWLEDGED,
    });

    const result = await controller.updateStatus(moderatorRequest, 'comp-1', {
      status: CivicComplaintStatus.ACKNOWLEDGED,
      note: 'Received',
    });

    expect(result.status).toBe(CivicComplaintStatus.ACKNOWLEDGED);
    expect(service.updateStatusByAuthority).toHaveBeenCalledWith(
      'mod-1',
      'MODERATOR',
      'comp-1',
      CivicComplaintStatus.ACKNOWLEDGED,
      'Received',
    );
  });

  it('citizen confirms resolution using JWT sub', async () => {
    service.confirmResolutionByCitizen.mockResolvedValue({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.CITIZEN_CONFIRMED,
    });

    const result = await controller.confirmResolution(
      authenticatedRequest,
      'comp-1',
    );

    expect(result.status).toBe(CivicComplaintStatus.CITIZEN_CONFIRMED);
    expect(service.confirmResolutionByCitizen).toHaveBeenCalledWith(
      'user-1',
      'comp-1',
    );
  });

  it('citizen reopens complaint using JWT sub and reason', async () => {
    service.reopenComplaintByCitizen.mockResolvedValue({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.REOPENED,
    });

    const result = await controller.reopenComplaint(authenticatedRequest, 'comp-1', {
      reason: 'Issue persists',
    });

    expect(result.status).toBe(CivicComplaintStatus.REOPENED);
    expect(service.reopenComplaintByCitizen).toHaveBeenCalledWith(
      'user-1',
      'comp-1',
      'Issue persists',
    );
  });
});
