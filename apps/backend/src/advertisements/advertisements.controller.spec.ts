import { Test, TestingModule } from '@nestjs/testing';
import { AdvertisementsController } from './advertisements.controller';
import { AdvertisementService } from './advertisements.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdvertisementPlacement } from '../generated/prisma/enums';

describe('AdvertisementsController', () => {
  let controller: AdvertisementsController;

  const mockAdvertisementService = {
    getPublicAdvertisements: jest.fn(),
    recordImpression: jest.fn(),
    recordClick: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdvertisementsController],
      providers: [
        {
          provide: AdvertisementService,
          useValue: mockAdvertisementService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<AdvertisementsController>(AdvertisementsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('getPublicAdvertisements', () => {
    it('delegates with placement, page and limit', async () => {
      mockAdvertisementService.getPublicAdvertisements.mockResolvedValue({
        items: [],
      });
      const query = {
        placement: AdvertisementPlacement.FEED,
        page: 2,
        limit: 5,
      };
      const result = await controller.getPublicAdvertisements(query);
      expect(result).toEqual({ items: [] });
      expect(
        mockAdvertisementService.getPublicAdvertisements,
      ).toHaveBeenCalledWith(AdvertisementPlacement.FEED, 2, 5);
    });
  });

  describe('tracking endpoints', () => {
    it('records an impression', async () => {
      mockAdvertisementService.recordImpression.mockResolvedValue({
        id: 'ad-1',
        impressionCount: 1,
        clickCount: 0,
      });
      const result = await controller.recordImpression('ad-1');
      expect(result.impressionCount).toBe(1);
      expect(mockAdvertisementService.recordImpression).toHaveBeenCalledWith(
        'ad-1',
      );
    });

    it('records a click', async () => {
      mockAdvertisementService.recordClick.mockResolvedValue({
        id: 'ad-1',
        impressionCount: 1,
        clickCount: 1,
      });
      const result = await controller.recordClick('ad-1');
      expect(result.clickCount).toBe(1);
      expect(mockAdvertisementService.recordClick).toHaveBeenCalledWith('ad-1');
    });
  });
});
