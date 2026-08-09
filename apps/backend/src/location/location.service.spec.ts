import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { LocationService } from './location.service';
import {
  LOCALITY_RESOLVER,
  LocalityResolver,
} from './locality/locality-resolver';

describe('LocationService', () => {
  let service: LocationService;

  const mockLocation = {
    id: 'location-123',
    latitude: 28.7041,
    longitude: 77.1025,
    accuracyMeters: 25,
    capturedAt: new Date('2026-08-09T08:00:00.000Z'),
    createdAt: new Date('2026-08-09T08:00:00.000Z'),
    updatedAt: new Date('2026-08-09T08:00:00.000Z'),
  };

  const mockDatabaseService = {
    userLocation: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  };

  const mockLocalityResolver: LocalityResolver = {
    resolve: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LocationService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
        },
        {
          provide: LOCALITY_RESOLVER,
          useValue: mockLocalityResolver,
        },
      ],
    }).compile();

    service = module.get<LocationService>(LocationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('finds the current location by authenticated user ID', async () => {
    mockDatabaseService.userLocation.findUnique.mockResolvedValue(mockLocation);

    const result = await service.findMe('user-123');

    expect(result).toEqual(mockLocation);
    expect(mockDatabaseService.userLocation.findUnique).toHaveBeenCalledWith({
      where: { userId: 'user-123' },
      select: expect.objectContaining({
        id: true,
        latitude: true,
        longitude: true,
        accuracyMeters: true,
        capturedAt: true,
        createdAt: true,
        updatedAt: true,
      }),
    });
  });

  it('returns null when the user has no location', async () => {
    mockDatabaseService.userLocation.findUnique.mockResolvedValue(null);

    await expect(service.findMe('user-123')).resolves.toBeNull();
  });

  it('creates the first location record', async () => {
    mockDatabaseService.userLocation.upsert.mockResolvedValue(mockLocation);
    const dto = {
      latitude: 28.7041,
      longitude: 77.1025,
      accuracyMeters: 25,
      capturedAt: '2026-08-09T08:00:00.000Z',
    };

    await service.updateMe('user-123', dto);

    expect(mockDatabaseService.userLocation.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-123' },
        create: expect.objectContaining({
          userId: 'user-123',
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracyMeters: dto.accuracyMeters,
          capturedAt: new Date(dto.capturedAt),
        }),
        update: expect.objectContaining({
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracyMeters: dto.accuracyMeters,
          capturedAt: new Date(dto.capturedAt),
        }),
      }),
    );
  });

  it('updates the existing location through the same upsert', async () => {
    mockDatabaseService.userLocation.upsert.mockResolvedValue(mockLocation);

    await service.updateMe('user-123', {
      latitude: 28.7,
      longitude: 77.1,
      capturedAt: '2026-08-09T09:00:00.000Z',
    });

    expect(mockDatabaseService.userLocation.upsert).toHaveBeenCalledTimes(1);
  });

  describe('findMyLocality', () => {
    it('returns null when the user has no location', async () => {
      mockDatabaseService.userLocation.findUnique.mockResolvedValue(null);

      await expect(service.findMyLocality('user-123')).resolves.toBeNull();
      expect(mockLocalityResolver.resolve).not.toHaveBeenCalled();
    });

    it('resolves locality from the authenticated user location', async () => {
      const locality = {
        id: 'development-locality-a',
        name: 'Test Locality A',
        city: 'Delhi',
        state: 'Delhi',
        country: 'India',
      };
      mockDatabaseService.userLocation.findUnique.mockResolvedValue({
        latitude: 28.7041,
        longitude: 77.1025,
      });
      (mockLocalityResolver.resolve as jest.Mock).mockReturnValue(locality);

      await expect(service.findMyLocality('user-123')).resolves.toEqual(
        locality,
      );
      expect(mockDatabaseService.userLocation.findUnique).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        select: { latitude: true, longitude: true },
      });
      expect(mockLocalityResolver.resolve).toHaveBeenCalledWith(
        28.7041,
        77.1025,
      );
    });

    it('returns null when the resolver cannot resolve coordinates', async () => {
      mockDatabaseService.userLocation.findUnique.mockResolvedValue({
        latitude: 0,
        longitude: 0,
      });
      (mockLocalityResolver.resolve as jest.Mock).mockReturnValue(null);

      await expect(service.findMyLocality('user-123')).resolves.toBeNull();
    });
  });
});
