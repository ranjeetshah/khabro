import { Inject, Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { UpdateLocationDto } from './dto/update-location.dto';
import { LOCALITY_RESOLVER } from './locality/locality-resolver';
import type {
  Locality,
  LocalityResolver,
} from './locality/locality-resolver';

const LOCATION_SELECT = {
  id: true,
  latitude: true,
  longitude: true,
  accuracyMeters: true,
  capturedAt: true,
  createdAt: true,
  updatedAt: true,
} as const;

@Injectable()
export class LocationService {
  constructor(
    private readonly database: DatabaseService,
    @Inject(LOCALITY_RESOLVER)
    private readonly localityResolver: LocalityResolver,
  ) {}

  async findMe(userId: string) {
    return this.database.userLocation.findUnique({
      where: { userId },
      select: LOCATION_SELECT,
    });
  }

  async updateMe(userId: string, dto: UpdateLocationDto) {
    return this.database.userLocation.upsert({
      where: { userId },
      create: {
        userId,
        latitude: dto.latitude,
        longitude: dto.longitude,
        accuracyMeters: dto.accuracyMeters,
        capturedAt: new Date(dto.capturedAt),
      },
      update: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        accuracyMeters: dto.accuracyMeters,
        capturedAt: new Date(dto.capturedAt),
      },
      select: LOCATION_SELECT,
    });
  }

  async findMyLocality(userId: string): Promise<Locality | null> {
    const location = await this.database.userLocation.findUnique({
      where: { userId },
      select: { latitude: true, longitude: true },
    });

    if (!location) {
      return null;
    }

    return this.localityResolver.resolve(location.latitude, location.longitude);
  }
}
