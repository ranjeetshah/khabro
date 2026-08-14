import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ModeratorGuard } from '../auth/guards/moderator.guard';
import { AdvertisementService } from './advertisements.service';
import { AdvertisementQueryDto } from './dto/advertisement-query.dto';
import { CreateAdvertisementDto } from './dto/create-advertisement.dto';
import { UpdateAdvertisementDto } from './dto/update-advertisement.dto';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
    role?: string;
  };
};

@Controller('moderator/advertisements')
@UseGuards(JwtAuthGuard, ModeratorGuard)
export class ModeratorAdvertisementsController {
  constructor(private readonly advertisementService: AdvertisementService) {}

  private userSub(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Post()
  async create(@Req() request: Request, @Body() dto: CreateAdvertisementDto) {
    return this.advertisementService.createAdvertisement(
      this.userSub(request),
      dto,
    );
  }

  @Get()
  async list(@Query() query: AdvertisementQueryDto) {
    return this.advertisementService.listAdvertisements(query);
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    return this.advertisementService.getAdvertisementDetail(id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateAdvertisementDto) {
    return this.advertisementService.updateAdvertisement(id, dto);
  }

  @Post(':id/activate')
  async activate(@Param('id') id: string) {
    return this.advertisementService.activateAdvertisement(id);
  }

  @Post(':id/pause')
  async pause(@Param('id') id: string) {
    return this.advertisementService.pauseAdvertisement(id);
  }

  @Delete(':id')
  async cancel(@Param('id') id: string) {
    return this.advertisementService.cancelAdvertisement(id);
  }
}
