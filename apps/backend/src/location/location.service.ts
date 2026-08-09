import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { UpdateLocationDto } from './dto/update-location.dto';

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
  constructor(private readonly database: DatabaseService) {}

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
}
