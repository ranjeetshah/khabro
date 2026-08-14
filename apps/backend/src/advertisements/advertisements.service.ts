import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import type { AdvertisementWhereInput } from '../generated/prisma/models/Advertisement';
import {
  AdvertisementPlacement,
  AdvertisementStatus,
} from '../generated/prisma/enums';
import { CreateAdvertisementDto } from './dto/create-advertisement.dto';
import { UpdateAdvertisementDto } from './dto/update-advertisement.dto';

const PUBLIC_SELECT = {
  id: true,
  title: true,
  description: true,
  advertiserName: true,
  creativeUrl: true,
  destinationUrl: true,
  ctaLabel: true,
  placement: true,
  status: true,
  startAt: true,
  endAt: true,
  impressionCount: true,
  clickCount: true,
  createdAt: true,
  updatedAt: true,
} as const;

const MODERATOR_SELECT = {
  ...PUBLIC_SELECT,
  createdById: true,
  deletedAt: true,
} as const;

@Injectable()
export class AdvertisementService {
  constructor(private readonly database: DatabaseService) {}

  async getPublicAdvertisements(
    placement?: AdvertisementPlacement,
    page = 1,
    limit = 5,
  ) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(20, Math.max(1, limit));
    const now = new Date();

    const where: AdvertisementWhereInput = {
      status: AdvertisementStatus.ACTIVE,
      deletedAt: null,
      AND: [
        {
          OR: [{ startAt: null }, { startAt: { lte: now } }],
        },
        {
          OR: [{ endAt: null }, { endAt: { gte: now } }],
        },
      ],
      ...(placement ? { placement } : {}),
    };

    const [items, total] = await Promise.all([
      this.database.advertisement.findMany({
        where,
        select: PUBLIC_SELECT,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: (safePage - 1) * safeLimit,
        take: safeLimit,
      }),
      this.database.advertisement.count({ where }),
    ]);

    return {
      items,
      page: safePage,
      limit: safeLimit,
      total,
      hasMore: (safePage - 1) * safeLimit + items.length < total,
    };
  }

  async recordImpression(id: string) {
    await this.findActiveForTracking(id);
    const updated = await this.database.advertisement.update({
      where: { id },
      data: { impressionCount: { increment: 1 } },
      select: { id: true, impressionCount: true, clickCount: true },
    });
    return { ...updated };
  }

  async recordClick(id: string) {
    await this.findActiveForTracking(id);
    const updated = await this.database.advertisement.update({
      where: { id },
      data: { clickCount: { increment: 1 } },
      select: { id: true, impressionCount: true, clickCount: true },
    });
    return { ...updated };
  }

  private async findActiveForTracking(id: string) {
    const ad = await this.database.advertisement.findFirst({
      where: { id, deletedAt: null },
      select: { id: true },
    });
    if (!ad) {
      throw new NotFoundException('Advertisement not found');
    }
    return ad;
  }

  // ----- Moderator operations -----

  async createAdvertisement(createdById: string, dto: CreateAdvertisementDto) {
    this.assertValidSchedule(dto.startAt, dto.endAt);

    const ad = await this.database.advertisement.create({
      data: {
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        advertiserName: dto.advertiserName.trim(),
        creativeUrl: dto.creativeUrl.trim(),
        destinationUrl: dto.destinationUrl.trim(),
        ctaLabel: dto.ctaLabel?.trim() || null,
        placement: dto.placement,
        status: AdvertisementStatus.DRAFT,
        startAt: dto.startAt ? new Date(dto.startAt) : null,
        endAt: dto.endAt ? new Date(dto.endAt) : null,
        createdById,
      },
      select: MODERATOR_SELECT,
    });
    return ad;
  }

  async listAdvertisements(query: {
    page: number;
    limit: number;
    status?: AdvertisementStatus;
    placement?: AdvertisementPlacement;
  }) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: AdvertisementWhereInput = {
      deletedAt: null,
      ...(query.status ? { status: query.status } : {}),
      ...(query.placement ? { placement: query.placement } : {}),
    };

    const [items, total] = await Promise.all([
      this.database.advertisement.findMany({
        where,
        select: MODERATOR_SELECT,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip,
        take: limit,
      }),
      this.database.advertisement.count({ where }),
    ]);

    return {
      items,
      page,
      limit,
      total,
      hasMore: skip + items.length < total,
    };
  }

  async getAdvertisementDetail(id: string) {
    const ad = await this.database.advertisement.findFirst({
      where: { id, deletedAt: null },
      select: MODERATOR_SELECT,
    });
    if (!ad) {
      throw new NotFoundException('Advertisement not found');
    }
    return ad;
  }

  async updateAdvertisement(id: string, dto: UpdateAdvertisementDto) {
    const existing = await this.getAdvertisementDetail(id);

    if (existing.status === AdvertisementStatus.ACTIVE) {
      throw new BadRequestException(
        'Cannot edit an active advertisement. Pause it first.',
      );
    }
    if (existing.status === AdvertisementStatus.EXPIRED) {
      throw new BadRequestException('Cannot edit an expired advertisement');
    }

    const nextStart = dto.startAt ? new Date(dto.startAt) : existing.startAt;
    const nextEnd = dto.endAt ? new Date(dto.endAt) : existing.endAt;
    this.assertValidSchedule(
      nextStart ? nextStart.toISOString() : undefined,
      nextEnd ? nextEnd.toISOString() : undefined,
    );

    const ad = await this.database.advertisement.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title.trim() }),
        ...(dto.description !== undefined && {
          description: dto.description.trim() || null,
        }),
        ...(dto.advertiserName !== undefined && {
          advertiserName: dto.advertiserName.trim(),
        }),
        ...(dto.creativeUrl !== undefined && {
          creativeUrl: dto.creativeUrl.trim(),
        }),
        ...(dto.destinationUrl !== undefined && {
          destinationUrl: dto.destinationUrl.trim(),
        }),
        ...(dto.ctaLabel !== undefined && {
          ctaLabel: dto.ctaLabel.trim() || null,
        }),
        ...(dto.startAt !== undefined && { startAt: nextStart }),
        ...(dto.endAt !== undefined && { endAt: nextEnd }),
      },
      select: MODERATOR_SELECT,
    });
    return ad;
  }

  async activateAdvertisement(id: string) {
    const existing = await this.getAdvertisementDetail(id);

    if (existing.deletedAt) {
      throw new BadRequestException(
        'Cancelled advertisements cannot be activated',
      );
    }

    if (existing.status === AdvertisementStatus.EXPIRED) {
      throw new BadRequestException(
        'Expired advertisements cannot be activated',
      );
    }

    if (existing.status === AdvertisementStatus.ACTIVE) {
      return existing;
    }

    if (
      existing.status !== AdvertisementStatus.DRAFT &&
      existing.status !== AdvertisementStatus.PAUSED
    ) {
      throw new BadRequestException(
        'Only DRAFT or PAUSED advertisements can be activated',
      );
    }

    const now = new Date();
    if (existing.endAt && existing.endAt < now) {
      throw new BadRequestException(
        'Advertisement end date has passed; it can no longer be activated',
      );
    }

    const ad = await this.database.advertisement.update({
      where: { id },
      data: { status: AdvertisementStatus.ACTIVE },
      select: MODERATOR_SELECT,
    });
    return ad;
  }

  async pauseAdvertisement(id: string) {
    const existing = await this.getAdvertisementDetail(id);

    if (existing.status !== AdvertisementStatus.ACTIVE) {
      throw new BadRequestException('Only ACTIVE advertisements can be paused');
    }

    const ad = await this.database.advertisement.update({
      where: { id },
      data: { status: AdvertisementStatus.PAUSED },
      select: MODERATOR_SELECT,
    });
    return ad;
  }

  async cancelAdvertisement(id: string) {
    await this.getAdvertisementDetail(id);

    const ad = await this.database.advertisement.update({
      where: { id },
      data: { deletedAt: new Date() },
      select: MODERATOR_SELECT,
    });
    return { id: ad.id, deletedAt: ad.deletedAt };
  }

  private assertValidSchedule(startAt?: string, endAt?: string) {
    if (!startAt || !endAt) return;
    const start = new Date(startAt);
    const end = new Date(endAt);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw new BadRequestException('Invalid schedule dates');
    }
    if (end <= start) {
      throw new BadRequestException('endAt must be after startAt');
    }
  }
}
