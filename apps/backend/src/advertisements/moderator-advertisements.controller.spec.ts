import { Test, TestingModule } from '@nestjs/testing';
import { ModeratorAdvertisementsController } from './moderator-advertisements.controller';
import { AdvertisementService } from './advertisements.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ModeratorGuard } from '../auth/guards/moderator.guard';
import {
  AdvertisementPlacement,
  AdvertisementStatus,
} from '../generated/prisma/enums';

describe('ModeratorAdvertisementsController', () => {
  let controller: ModeratorAdvertisementsController;

  const mockAdvertisementService = {
    createAdvertisement: jest.fn(),
    listAdvertisements: jest.fn(),
    getAdvertisementDetail: jest.fn(),
    updateAdvertisement: jest.fn(),
    activateAdvertisement: jest.fn(),
    pauseAdvertisement: jest.fn(),
    cancelAdvertisement: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ModeratorAdvertisementsController],
      providers: [
        {
          provide: AdvertisementService,
          useValue: mockAdvertisementService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(ModeratorGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<ModeratorAdvertisementsController>(
      ModeratorAdvertisementsController,
    );
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('creates with the JWT subject as the owner', async () => {
      mockAdvertisementService.createAdvertisement.mockResolvedValue({
        id: 'ad-new',
        status: AdvertisementStatus.DRAFT,
      });
      const dto = {
        title: 'Cleanup Drive',
        advertiserName: 'City Civic',
        creativeUrl: 'https://cdn.example.com/creative.jpg',
        destinationUrl: 'https://example.com/cleanup',
        placement: AdvertisementPlacement.FEED,
      };
      const req = { user: { sub: 'mod-1' } } as { user: { sub: string } };

      const result = await controller.create(req, dto);
      expect(result.status).toBe(AdvertisementStatus.DRAFT);
      expect(mockAdvertisementService.createAdvertisement).toHaveBeenCalledWith(
        'mod-1',
        dto,
      );
    });
  });

  describe('list', () => {
    it('delegates the query to the service', async () => {
      mockAdvertisementService.listAdvertisements.mockResolvedValue({
        items: [],
      });
      const query = {
        page: 1,
        limit: 20,
        status: AdvertisementStatus.ACTIVE,
        placement: AdvertisementPlacement.FEED,
      };
      const result = await controller.list(query);
      expect(result).toEqual({ items: [] });
      expect(mockAdvertisementService.listAdvertisements).toHaveBeenCalledWith(
        query,
      );
    });
  });

  describe('detail', () => {
    it('fetches a single advertisement', async () => {
      mockAdvertisementService.getAdvertisementDetail.mockResolvedValue({
        id: 'ad-1',
      });
      const result = await controller.detail('ad-1');
      expect(result.id).toBe('ad-1');
      expect(
        mockAdvertisementService.getAdvertisementDetail,
      ).toHaveBeenCalledWith('ad-1');
    });
  });

  describe('update', () => {
    it('delegates id and dto', async () => {
      mockAdvertisementService.updateAdvertisement.mockResolvedValue({
        id: 'ad-1',
        title: 'Updated',
      });
      const dto = { title: 'Updated' };
      const result = await controller.update('ad-1', dto);
      expect(result.title).toBe('Updated');
      expect(mockAdvertisementService.updateAdvertisement).toHaveBeenCalledWith(
        'ad-1',
        dto,
      );
    });
  });

  describe('lifecycle actions', () => {
    it('activates an advertisement', async () => {
      mockAdvertisementService.activateAdvertisement.mockResolvedValue({
        id: 'ad-1',
        status: AdvertisementStatus.ACTIVE,
      });
      const result = await controller.activate('ad-1');
      expect(result.status).toBe(AdvertisementStatus.ACTIVE);
      expect(
        mockAdvertisementService.activateAdvertisement,
      ).toHaveBeenCalledWith('ad-1');
    });

    it('pauses an advertisement', async () => {
      mockAdvertisementService.pauseAdvertisement.mockResolvedValue({
        id: 'ad-1',
        status: AdvertisementStatus.PAUSED,
      });
      const result = await controller.pause('ad-1');
      expect(result.status).toBe(AdvertisementStatus.PAUSED);
      expect(mockAdvertisementService.pauseAdvertisement).toHaveBeenCalledWith(
        'ad-1',
      );
    });

    it('cancels an advertisement', async () => {
      mockAdvertisementService.cancelAdvertisement.mockResolvedValue({
        id: 'ad-1',
        deletedAt: new Date(),
      });
      const result = await controller.cancel('ad-1');
      expect(result.id).toBe('ad-1');
      expect(mockAdvertisementService.cancelAdvertisement).toHaveBeenCalledWith(
        'ad-1',
      );
    });
  });
});
