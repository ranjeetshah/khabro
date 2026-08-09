import { Inject, Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { UpdateLocationDto } from './dto/update-location.dto';
import { LOCALITY_RESOLVER } from './locality/locality-resolver';
import type {
  LocalitySummary,
  LocalityResolver,
} from './locality/locality-resolver';

const LOCALITY_SELECT = {
  id: true,
  name: true,
  city: true,
  state: true,
  country: true,
} as const;

const LOCATION_SELECT = {
  id: true,
  capturedAt: true,
  createdAt: true,
  updatedAt: true,
  locality: { select: LOCALITY_SELECT },
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
    const locality = this.localityResolver.resolve(
      dto.latitude,
      dto.longitude,
    );

    return this.database.$transaction((transaction) =>
      transaction.userLocation.upsert({
        where: { userId },
        create: {
          userId,
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracyMeters: dto.accuracyMeters,
          capturedAt: new Date(dto.capturedAt),
          localityId: locality?.id ?? null,
        },
        update: {
          latitude: dto.latitude,
          longitude: dto.longitude,
          accuracyMeters: dto.accuracyMeters,
          capturedAt: new Date(dto.capturedAt),
          localityId: locality?.id ?? null,
        },
        select: LOCATION_SELECT,
      }),
    );
  }

  async findMyLocality(userId: string): Promise<LocalitySummary | null> {
    const location = await this.database.userLocation.findUnique({
      where: { userId },
      select: { locality: { select: LOCALITY_SELECT } },
    });

    return location?.locality ?? null;
  }
}
