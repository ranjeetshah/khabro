import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { CivicComplaintStatus, VerificationStatus } from '../generated/prisma/enums';
import { MailService } from '../mail/mail.service';
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

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CivicComplaintService,
        { provide: DatabaseService, useValue: database },
        { provide: MailService, useValue: mailService },
        { provide: ConfigService, useValue: configService },
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
});
