import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { CivicComplaintStatus, VerificationStatus } from '../generated/prisma/enums';
import { MailService } from '../mail/mail.service';
import { NotificationService } from '../notifications/notification.service';
import { CivicComplaintService } from './civic-complaint.service';

describe('CivicComplaintService', () => {
  let service: CivicComplaintService;
  let database: any;
  let mailService: any;
  let configService: any;

  const mockPost = {
    id: 'post-1',
    content: 'Pothole on Main St',
    verificationStatus: VerificationStatus.LOCALLY_VERIFIED,
    createdAt: new Date('2026-08-01T10:00:00Z'),
    authorId: 'author-1',
    locality: {
      name: 'Downtown',
      city: 'Metropolis',
      state: 'State',
      country: 'Country',
    },
  };

  beforeEach(async () => {
    database = {
      post: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
      },
      witness: {
        count: jest.fn(),
        findMany: jest.fn(),
      },
      civicComplaint: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    mailService = {
      sendEmail: jest.fn(),
    };

    configService = {
      get: jest.fn((key: string) => {
        if (key === 'CIVIC_COMPLAINT_AUTHORITY_EMAIL') {
          return 'authority@example.gov.in';
        }
        if (key === 'CIVIC_COMPLAINT_WITNESS_THRESHOLD') {
          return '20';
        }
        if (key === 'CIVIC_COMPLAINT_MAX_CC_WITNESSES') {
          return '20';
        }
        return null;
      }),
    };

    const notificationService = {
      createCivicComplaintNotification: jest.fn().mockResolvedValue(null),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CivicComplaintService,
        { provide: DatabaseService, useValue: database },
        { provide: MailService, useValue: mailService },
        { provide: ConfigService, useValue: configService },
        { provide: NotificationService, useValue: notificationService },
      ],
    }).compile();

    service = module.get<CivicComplaintService>(CivicComplaintService);
  });

  it('defaults threshold to 20 and threshold is configurable', () => {
    expect(service.witnessThreshold).toBe(20);
    configService.get.mockImplementation((key: string) =>
      key === 'CIVIC_COMPLAINT_WITNESS_THRESHOLD' ? 15 : null,
    );
    expect(service.witnessThreshold).toBe(15);
  });

  it('19 witnesses do NOT create a complaint', async () => {
    database.post.findFirst.mockResolvedValue(mockPost);
    database.witness.count.mockResolvedValue(19);

    const result = await service.evaluateAndGenerateComplaint('post-1');
    expect(result).toBeNull();
    expect(database.civicComplaint.create).not.toHaveBeenCalled();
  });

  it('20 unique witnesses create DRAFT complaint and trigger email to authority', async () => {
    database.post.findFirst.mockResolvedValue(mockPost);
    database.witness.count.mockResolvedValue(20);
    database.civicComplaint.findUnique.mockResolvedValue(null);
    database.witness.findMany.mockResolvedValue([
      { user: { name: 'OptedIn Witness', phone: '+1234567890' } },
    ]);
    database.civicComplaint.create.mockImplementation((args: any) =>
      Promise.resolve({
        id: 'complaint-1',
        ...args.data,
      }),
    );
    mailService.sendEmail.mockResolvedValue(true);
    database.civicComplaint.update.mockResolvedValue({
      id: 'complaint-1',
      status: CivicComplaintStatus.SENT,
      sentAt: new Date(),
    });

    const result = await service.evaluateAndGenerateComplaint('post-1');

    expect(database.civicComplaint.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          postId: 'post-1',
          witnessCount: 20,
          status: CivicComplaintStatus.DRAFT,
        }),
      }),
    );
    expect(mailService.sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'authority@example.gov.in',
      }),
    );
    expect(database.civicComplaint.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: CivicComplaintStatus.SENT,
        }),
      }),
    );
  });

  it('does NOT create another complaint or trigger email if post already has a complaint', async () => {
    database.post.findFirst.mockResolvedValue(mockPost);
    database.witness.count.mockResolvedValue(20);
    database.civicComplaint.findUnique.mockResolvedValue({
      id: 'complaint-1',
      status: CivicComplaintStatus.SENT,
    });

    const result = await service.evaluateAndGenerateComplaint('post-1');

    expect(result).toEqual({ id: 'complaint-1', status: CivicComplaintStatus.SENT });
    expect(database.civicComplaint.create).not.toHaveBeenCalled();
    expect(mailService.sendEmail).not.toHaveBeenCalled();
  });

  it('REPORTED or UNDER_VERIFICATION posts cannot create a complaint', async () => {
    database.post.findFirst.mockResolvedValue({
      ...mockPost,
      verificationStatus: VerificationStatus.UNDER_VERIFICATION,
    });

    const result = await service.evaluateAndGenerateComplaint('post-1');
    expect(result).toBeNull();
    expect(database.civicComplaint.create).not.toHaveBeenCalled();
  });

  it('marks complaint as FAILED when email dispatch fails', async () => {
    database.post.findFirst.mockResolvedValue(mockPost);
    database.witness.count.mockResolvedValue(20);
    database.civicComplaint.findUnique.mockResolvedValue(null);
    database.witness.findMany.mockResolvedValue([]);
    database.civicComplaint.create.mockResolvedValue({
      id: 'complaint-1',
      postId: 'post-1',
      status: CivicComplaintStatus.DRAFT,
      subject: 'Sub',
      body: 'Body',
    });
    mailService.sendEmail.mockResolvedValue(false);
    database.civicComplaint.update.mockResolvedValue({
      id: 'complaint-1',
      status: CivicComplaintStatus.FAILED,
    });

    const result = await service.evaluateAndGenerateComplaint('post-1');

    expect(database.civicComplaint.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: CivicComplaintStatus.FAILED }),
      }),
    );
  });

  it('only includes explicitly opted-in witness contact info in complaint body', async () => {
    database.post.findFirst.mockResolvedValue(mockPost);
    database.witness.count.mockResolvedValue(20);
    database.civicComplaint.findUnique.mockResolvedValue(null);
    database.witness.findMany.mockResolvedValue([
      { user: { name: 'Alice', phone: '+111111' } },
    ]);
    database.civicComplaint.create.mockImplementation((args: any) =>
      Promise.resolve({ id: 'comp-1', ...args.data }),
    );
    mailService.sendEmail.mockResolvedValue(true);
    database.civicComplaint.update.mockResolvedValue({ id: 'comp-1', status: CivicComplaintStatus.SENT });

    await service.evaluateAndGenerateComplaint('post-1');

    expect(database.witness.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          user: { allowCivicComplaintContactSharing: true },
        }),
      }),
    );
  });

  it('getComplaintForPost returns safe public complaint fields only', async () => {
    database.post.findFirst.mockResolvedValue({ id: 'post-1' });
    database.civicComplaint.findUnique.mockResolvedValue({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.SENT,
      witnessCount: 20,
      sentAt: new Date('2026-08-01T12:00:00Z'),
    });

    const res = await service.getComplaintForPost('post-1');

    expect(res).toEqual({
      referenceCode: 'KH-2026-000123',
      status: CivicComplaintStatus.SENT,
      witnessCount: 20,
      sentAt: new Date('2026-08-01T12:00:00Z'),
    });
    expect(res).not.toHaveProperty('authorityEmail');
    expect(res).not.toHaveProperty('body');
  });

  it('getComplaintForPost throws NotFoundException if no complaint or post deleted', async () => {
    database.post.findFirst.mockResolvedValue(null);
    await expect(service.getComplaintForPost('post-1')).rejects.toThrow(
      NotFoundException,
    );
  });

  describe('State Machine & Transitions', () => {
    it('validates allowed transitions correctly', () => {
      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.SENT,
          CivicComplaintStatus.ACKNOWLEDGED,
        ),
      ).not.toThrow();

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.ACKNOWLEDGED,
          CivicComplaintStatus.IN_PROGRESS,
        ),
      ).not.toThrow();

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.IN_PROGRESS,
          CivicComplaintStatus.RESOLVED,
        ),
      ).not.toThrow();

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.RESOLVED,
          CivicComplaintStatus.CITIZEN_CONFIRMED,
        ),
      ).not.toThrow();

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.RESOLVED,
          CivicComplaintStatus.REOPENED,
        ),
      ).not.toThrow();

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.REOPENED,
          CivicComplaintStatus.ACKNOWLEDGED,
        ),
      ).not.toThrow();
    });

    it('rejects invalid transitions', () => {
      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.SENT,
          CivicComplaintStatus.RESOLVED,
        ),
      ).toThrow(BadRequestException);

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.SENT,
          CivicComplaintStatus.CITIZEN_CONFIRMED,
        ),
      ).toThrow(BadRequestException);

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.ACKNOWLEDGED,
          CivicComplaintStatus.CITIZEN_CONFIRMED,
        ),
      ).toThrow(BadRequestException);

      expect(() =>
        service.validateStatusTransition(
          CivicComplaintStatus.REOPENED,
          CivicComplaintStatus.CITIZEN_CONFIRMED,
        ),
      ).toThrow(BadRequestException);
    });

    it('rejects non-moderator from performing authority status updates', async () => {
      database.user = {
        findUnique: jest.fn().mockResolvedValue({ role: 'CITIZEN' }),
      };

      await expect(
        service.updateStatusByAuthority(
          'user-1',
          'CITIZEN',
          'comp-1',
          CivicComplaintStatus.ACKNOWLEDGED,
        ),
      ).rejects.toThrow();
    });

    it('allows moderator to perform valid authority status updates and records history', async () => {
      database.user = {
        findUnique: jest.fn().mockResolvedValue({ role: 'MODERATOR' }),
      };
      database.civicComplaint.findFirst = jest.fn().mockResolvedValue({
        id: 'comp-1',
        status: CivicComplaintStatus.SENT,
        referenceCode: 'KH-2026-000123',
      });
      database.civicComplaint.update = jest.fn().mockResolvedValue({
        referenceCode: 'KH-2026-000123',
        status: CivicComplaintStatus.ACKNOWLEDGED,
        createdAt: new Date(),
        sentAt: new Date(),
        updatedAt: new Date(),
      });
      database.civicComplaintStatusHistory = { create: jest.fn() };
      database.$transaction = jest.fn((cb) => cb(database));

      const res = await service.updateStatusByAuthority(
        'mod-1',
        'MODERATOR',
        'comp-1',
        CivicComplaintStatus.ACKNOWLEDGED,
        'Received',
      );

      expect(res.status).toBe(CivicComplaintStatus.ACKNOWLEDGED);
      expect(database.civicComplaintStatusHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            complaintId: 'comp-1',
            fromStatus: CivicComplaintStatus.SENT,
            toStatus: CivicComplaintStatus.ACKNOWLEDGED,
            actorId: 'mod-1',
            note: 'Received',
          }),
        }),
      );
    });

    it('citizen can confirm a RESOLVED complaint', async () => {
      database.civicComplaint.findFirst = jest.fn().mockResolvedValue({
        id: 'comp-1',
        status: CivicComplaintStatus.RESOLVED,
        referenceCode: 'KH-2026-000123',
      });
      database.civicComplaint.update = jest.fn().mockResolvedValue({
        referenceCode: 'KH-2026-000123',
        status: CivicComplaintStatus.CITIZEN_CONFIRMED,
        createdAt: new Date(),
        sentAt: new Date(),
        updatedAt: new Date(),
      });
      database.civicComplaintStatusHistory = { create: jest.fn() };
      database.$transaction = jest.fn((cb) => cb(database));

      const res = await service.confirmResolutionByCitizen('citizen-1', 'comp-1');

      expect(res.status).toBe(CivicComplaintStatus.CITIZEN_CONFIRMED);
      expect(database.civicComplaintStatusHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            toStatus: CivicComplaintStatus.CITIZEN_CONFIRMED,
            actorId: 'citizen-1',
          }),
        }),
      );
    });

    it('citizen can reopen a RESOLVED complaint with a reason', async () => {
      database.civicComplaint.findFirst = jest.fn().mockResolvedValue({
        id: 'comp-1',
        status: CivicComplaintStatus.RESOLVED,
        referenceCode: 'KH-2026-000123',
      });
      database.civicComplaint.update = jest.fn().mockResolvedValue({
        referenceCode: 'KH-2026-000123',
        status: CivicComplaintStatus.REOPENED,
        createdAt: new Date(),
        sentAt: new Date(),
        updatedAt: new Date(),
      });
      database.civicComplaintStatusHistory = { create: jest.fn() };
      database.$transaction = jest.fn((cb) => cb(database));

      const res = await service.reopenComplaintByCitizen(
        'citizen-1',
        'comp-1',
        'The road is still blocked.',
      );

      expect(res.status).toBe(CivicComplaintStatus.REOPENED);
      expect(database.civicComplaintStatusHistory.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            toStatus: CivicComplaintStatus.REOPENED,
            actorId: 'citizen-1',
            note: 'The road is still blocked.',
          }),
        }),
      );
    });

    it('getStatusHistory returns history items without exposing actorId', async () => {
      database.civicComplaint.findFirst = jest.fn().mockResolvedValue({ id: 'comp-1' });
      database.civicComplaintStatusHistory = {
        findMany: jest.fn().mockResolvedValue([
          {
            fromStatus: CivicComplaintStatus.SENT,
            toStatus: CivicComplaintStatus.ACKNOWLEDGED,
            note: 'Assigned',
            createdAt: new Date(),
          },
        ]),
      };

      const history = await service.getStatusHistory('comp-1');

      expect(history.length).toBe(1);
      expect(history[0]).not.toHaveProperty('actorId');
      expect(history[0].toStatus).toBe(CivicComplaintStatus.ACKNOWLEDGED);
    });
  });
});
