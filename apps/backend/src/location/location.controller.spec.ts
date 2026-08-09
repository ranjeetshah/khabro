import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { LocationController } from './location.controller';
import { LocationService } from './location.service';

describe('LocationController', () => {
  let controller: LocationController;

  const mockLocation = {
    id: 'location-123',
    latitude: 28.7041,
    longitude: 77.1025,
    accuracyMeters: 25,
    capturedAt: new Date('2026-08-09T08:00:00.000Z'),
    createdAt: new Date('2026-08-09T08:00:00.000Z'),
    updatedAt: new Date('2026-08-09T08:00:00.000Z'),
  };

  const mockLocationService = {
    findMe: jest.fn(),
    updateMe: jest.fn(),
    findMyLocality: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [LocationController],
      providers: [
        {
          provide: LocationService,
          useValue: mockLocationService,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<LocationController>(LocationController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('GET /location/me returns the authenticated user location', async () => {
    mockLocationService.findMe.mockResolvedValue(mockLocation);

    const result = await controller.getMe({ user: { sub: 'user-123' } } as any);

    expect(mockLocationService.findMe).toHaveBeenCalledWith('user-123');
    expect(result).toEqual({ location: mockLocation });
  });

  it('GET /location/me returns null when no location exists', async () => {
    mockLocationService.findMe.mockResolvedValue(null);

    await expect(
      controller.getMe({ user: { sub: 'user-123' } } as any),
    ).resolves.toEqual({ location: null });
  });

  it('PUT /location/me uses the JWT subject and ignores body identity fields', async () => {
    mockLocationService.updateMe.mockResolvedValue(mockLocation);
    const dto = {
      latitude: 28.7041,
      longitude: 77.1025,
      accuracyMeters: 25,
      capturedAt: '2026-08-09T08:00:00.000Z',
    };

    await controller.updateMe(
      {
        user: { sub: 'user-123' },
        body: { userId: 'attacker-id', id: 'attacker-id' },
      } as any,
      dto,
    );

    expect(mockLocationService.updateMe).toHaveBeenCalledWith('user-123', dto);
  });

  it('rejects requests without a JWT subject', async () => {
    await expect(controller.getMe({ user: {} } as any)).rejects.toThrow(
      UnauthorizedException,
    );
    await expect(
      controller.updateMe({ user: {} } as any, {} as any),
    ).rejects.toThrow(UnauthorizedException);
    expect(mockLocationService.findMe).not.toHaveBeenCalled();
    expect(mockLocationService.updateMe).not.toHaveBeenCalled();
  });

  it('GET /location/me/locality returns only locality fields', async () => {
    const locality = {
      id: 'development-locality-a',
      name: 'Test Locality A',
      type: 'LOCALITY',
      parent: {
        id: 'development-city-delhi',
        name: 'Delhi',
        type: 'CITY',
        parent: null,
      },
      city: 'Delhi',
      state: 'Delhi',
      country: 'India',
    };
    mockLocationService.findMyLocality.mockResolvedValue(locality);

    const result = await controller.getMyLocality({
      user: { sub: 'user-123' },
      query: { userId: 'attacker-id' },
    } as any);

    expect(mockLocationService.findMyLocality).toHaveBeenCalledWith('user-123');
    expect(result).toEqual({
      locality: {
        id: locality.id,
        name: locality.name,
        city: locality.city,
        state: locality.state,
        country: locality.country,
      },
    });
    expect(JSON.stringify(result)).not.toContain('parent');
    expect(JSON.stringify(result)).not.toContain('latitude');
    expect(JSON.stringify(result)).not.toContain('longitude');
  });

  it('GET /location/me/locality returns null when unresolved', async () => {
    mockLocationService.findMyLocality.mockResolvedValue(null);

    await expect(
      controller.getMyLocality({ user: { sub: 'user-123' } } as any),
    ).resolves.toEqual({ locality: null });
  });

  it('rejects locality requests without a JWT subject', async () => {
    await expect(controller.getMyLocality({ user: {} } as any)).rejects.toThrow(
      UnauthorizedException,
    );
    expect(mockLocationService.findMyLocality).not.toHaveBeenCalled();
  });
});
