import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { LocationService } from './location.service';

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

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LocationService,
        {
          provide: DatabaseService,
          useValue: mockDatabaseService,
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
});
