import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import {
  AdvertisementPlacement,
  AdvertisementStatus,
} from '../generated/prisma/enums';
import { AdvertisementService } from './advertisements.service';

describe('AdvertisementService', () => {
  let service: AdvertisementService;
  let databaseService: any;

  const baseAd = {
    id: 'ad-1',
    title: 'City Cleanup Drive',
    description: 'Join us',
    advertiserName: 'City Civic',
    creativeUrl: 'https://cdn.example.com/creative.jpg',
    destinationUrl: 'https://example.com/cleanup',
    ctaLabel: 'Learn more',
    placement: AdvertisementPlacement.FEED,
    status: AdvertisementStatus.ACTIVE,
    startAt: new Date('2026-01-01T00:00:00.000Z'),
    endAt: new Date('2027-01-01T00:00:00.000Z'),
    impressionCount: 0,
    clickCount: 0,
    createdById: 'mod-1',
    createdAt: new Date('2026-08-01T00:00:00.000Z'),
    updatedAt: new Date('2026-08-01T00:00:01.000Z'),
    deletedAt: null,
  };

  beforeEach(async () => {
    databaseService = {
      advertisement: {
        findMany: jest.fn(),
        count: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      $transaction: jest.fn((cb) => cb(databaseService)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdvertisementService,
        { provide: DatabaseService, useValue: databaseService },
      ],
    }).compile();

    service = module.get<AdvertisementService>(AdvertisementService);
  });

  describe('getPublicAdvertisements', () => {
    beforeEach(() => {
      databaseService.advertisement.findMany.mockResolvedValue([]);
      databaseService.advertisement.count.mockResolvedValue(0);
    });

    it('returns an empty page when no advertisements exist', async () => {
      const result = await service.getPublicAdvertisements(
        AdvertisementPlacement.FEED,
        1,
        5,
      );
      expect(result.items).toEqual([]);
      expect(result.hasMore).toBe(false);
    });

    it('queries only ACTIVE, non-deleted, in-window advertisements', async () => {
      await service.getPublicAdvertisements(AdvertisementPlacement.FEED, 1, 5);

      const where =
        databaseService.advertisement.findMany.mock.calls[0][0].where;
      expect(where.status).toBe(AdvertisementStatus.ACTIVE);
      expect(where.deletedAt).toBeNull();
      expect(where.placement).toBe(AdvertisementPlacement.FEED);

      const startWindow = where.AND[0].OR;
      expect(startWindow).toContainEqual({ startAt: null });
      expect(startWindow[1].startAt).toHaveProperty('lte');

      const endWindow = where.AND[1].OR;
      expect(endWindow).toContainEqual({ endAt: null });
      expect(endWindow[1].endAt).toHaveProperty('gte');
    });

    it('omits the placement filter when placement is not provided', async () => {
      await service.getPublicAdvertisements(undefined, 1, 5);
      const where =
        databaseService.advertisement.findMany.mock.calls[0][0].where;
      expect(where.placement).toBeUndefined();
    });

    it('enforces the maximum public limit of 20', async () => {
      await service.getPublicAdvertisements(undefined, 1, 999);
      expect(databaseService.advertisement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ take: 20 }),
      );
    });

    it('orders deterministically by createdAt DESC then id DESC', async () => {
      await service.getPublicAdvertisements(undefined, 1, 5);
      expect(databaseService.advertisement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        }),
      );
    });

    it('computes hasMore based on the total count', async () => {
      databaseService.advertisement.findMany.mockResolvedValue([baseAd]);
      databaseService.advertisement.count.mockResolvedValue(2);

      const result = await service.getPublicAdvertisements(undefined, 1, 5);
      expect(result.items).toHaveLength(1);
      expect(result.hasMore).toBe(true);
    });

    it('does not leak createdById or deletedAt to the public', async () => {
      databaseService.advertisement.findMany.mockResolvedValue([baseAd]);
      const result = await service.getPublicAdvertisements(
        AdvertisementPlacement.FEED,
        1,
        5,
      );
      const select =
        databaseService.advertisement.findMany.mock.calls[0][0].select;
      expect(select).not.toHaveProperty('createdById');
      expect(select).not.toHaveProperty('deletedAt');
      expect(select).toHaveProperty('destinationUrl');
      expect(result.items[0].destinationUrl).toBe(baseAd.destinationUrl);
    });
  });

  describe('tracking counters', () => {
    it('increments impressionCount atomically', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        id: 'ad-1',
      });
      databaseService.advertisement.update.mockResolvedValue({
        id: 'ad-1',
        impressionCount: 1,
        clickCount: 0,
      });

      const result = await service.recordImpression('ad-1');
      expect(result.impressionCount).toBe(1);
      expect(databaseService.advertisement.update).toHaveBeenCalledWith({
        where: { id: 'ad-1' },
        data: { impressionCount: { increment: 1 } },
        select: expect.anything(),
      });
    });

    it('increments clickCount atomically', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        id: 'ad-1',
      });
      databaseService.advertisement.update.mockResolvedValue({
        id: 'ad-1',
        impressionCount: 10,
        clickCount: 2,
      });

      const result = await service.recordClick('ad-1');
      expect(result.clickCount).toBe(2);
      expect(databaseService.advertisement.update).toHaveBeenCalledWith({
        where: { id: 'ad-1' },
        data: { clickCount: { increment: 1 } },
        select: expect.anything(),
      });
    });

    it('throws NotFound when tracking an unknown advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue(null);
      await expect(service.recordImpression('ad-unknown')).rejects.toThrow(
        NotFoundException,
      );
      await expect(service.recordClick('ad-unknown')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('createAdvertisement', () => {
    const createDto = {
      title: 'Cleanup Drive',
      description: 'Join us',
      advertiserName: 'City Civic',
      creativeUrl: 'https://cdn.example.com/creative.jpg',
      destinationUrl: 'https://example.com/cleanup',
      ctaLabel: 'Learn more',
      placement: AdvertisementPlacement.FEED,
    };

    it('creates a DRAFT advertisement owned by the actor', async () => {
      databaseService.advertisement.create.mockResolvedValue({
        ...baseAd,
        id: 'ad-new',
        status: AdvertisementStatus.DRAFT,
      });

      const result = await service.createAdvertisement('mod-1', createDto);

      expect(databaseService.advertisement.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            createdById: 'mod-1',
            status: AdvertisementStatus.DRAFT,
            placement: AdvertisementPlacement.FEED,
          }),
        }),
      );
      expect(result.status).toBe(AdvertisementStatus.DRAFT);
    });

    it('rejects a schedule where endAt is not after startAt', async () => {
      await expect(
        service.createAdvertisement('mod-1', {
          ...createDto,
          startAt: '2026-12-01T00:00:00.000Z',
          endAt: '2026-10-01T00:00:00.000Z',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('listAdvertisements', () => {
    beforeEach(() => {
      databaseService.advertisement.findMany.mockResolvedValue([]);
      databaseService.advertisement.count.mockResolvedValue(0);
    });

    it('paginates and filters by status and placement', async () => {
      databaseService.advertisement.findMany.mockResolvedValue([]);
      databaseService.advertisement.count.mockResolvedValue(0);

      await service.listAdvertisements({
        page: 2,
        limit: 10,
        status: AdvertisementStatus.DRAFT,
        placement: AdvertisementPlacement.FEED,
      });

      const [findCall, countCall] = [
        databaseService.advertisement.findMany.mock.calls[0][0],
        databaseService.advertisement.count.mock.calls[0][0],
      ];
      expect(findCall.skip).toBe(10);
      expect(findCall.take).toBe(10);
      expect(findCall.where.status).toBe(AdvertisementStatus.DRAFT);
      expect(findCall.where.placement).toBe(AdvertisementPlacement.FEED);
      expect(countCall.where.status).toBe(AdvertisementStatus.DRAFT);
    });

    it('clamps limit to a maximum of 50', async () => {
      await service.listAdvertisements({ page: 1, limit: 999 });
      expect(databaseService.advertisement.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ take: 50 }),
      );
    });

    it('excludes cancelled advertisements by default', async () => {
      await service.listAdvertisements({ page: 1, limit: 20 });
      const where =
        databaseService.advertisement.findMany.mock.calls[0][0].where;
      expect(where.deletedAt).toBeNull();
    });
  });

  describe('updateAdvertisement', () => {
    it('updates editable fields of a DRAFT advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.DRAFT,
      });
      databaseService.advertisement.update.mockResolvedValue({
        ...baseAd,
        title: 'New Title',
      });

      const result = await service.updateAdvertisement('ad-1', {
        title: 'New Title',
      });

      expect(result.title).toBe('New Title');
      expect(databaseService.advertisement.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ title: 'New Title' }),
        }),
      );
    });

    it('rejects editing an ACTIVE advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue(baseAd);

      await expect(
        service.updateAdvertisement('ad-1', { title: 'New Title' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects editing an EXPIRED advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.EXPIRED,
      });

      await expect(
        service.updateAdvertisement('ad-1', { title: 'New Title' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('activateAdvertisement', () => {
    it('activates a DRAFT advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.DRAFT,
      });
      databaseService.advertisement.update.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.ACTIVE,
      });

      const result = await service.activateAdvertisement('ad-1');
      expect(result.status).toBe(AdvertisementStatus.ACTIVE);
      expect(databaseService.advertisement.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { status: AdvertisementStatus.ACTIVE },
        }),
      );
    });

    it('resumes a PAUSED advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.PAUSED,
      });
      databaseService.advertisement.update.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.ACTIVE,
      });

      const result = await service.activateAdvertisement('ad-1');
      expect(result.status).toBe(AdvertisementStatus.ACTIVE);
    });

    it('rejects activating an EXPIRED advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.EXPIRED,
      });

      await expect(service.activateAdvertisement('ad-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects activating when the end date has already passed', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.DRAFT,
        endAt: new Date('2020-01-01T00:00:00.000Z'),
      });

      await expect(service.activateAdvertisement('ad-1')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('pauseAdvertisement', () => {
    it('pauses an ACTIVE advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue(baseAd);
      databaseService.advertisement.update.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.PAUSED,
      });

      const result = await service.pauseAdvertisement('ad-1');
      expect(result.status).toBe(AdvertisementStatus.PAUSED);
    });

    it('rejects pausing a DRAFT advertisement', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue({
        ...baseAd,
        status: AdvertisementStatus.DRAFT,
      });

      await expect(service.pauseAdvertisement('ad-1')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('cancelAdvertisement', () => {
    it('soft-deletes an advertisement and preserves its data', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue(baseAd);
      databaseService.advertisement.update.mockResolvedValue({
        ...baseAd,
        deletedAt: new Date('2026-08-13T00:00:00.000Z'),
      });

      const result = await service.cancelAdvertisement('ad-1');
      expect(result.id).toBe('ad-1');
      expect(result.deletedAt).toBeInstanceOf(Date);
      expect(databaseService.advertisement.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ deletedAt: expect.any(Date) }),
        }),
      );
    });

    it('throws NotFound for unknown advertisements', async () => {
      databaseService.advertisement.findFirst.mockResolvedValue(null);

      await expect(service.cancelAdvertisement('ad-unknown')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
