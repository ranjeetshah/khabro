import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdvertisementService } from './advertisements.service';
import { PublicAdvertisementQueryDto } from './dto/advertisement-query.dto';

@Controller('advertisements')
@UseGuards(JwtAuthGuard)
export class AdvertisementsController {
  constructor(private readonly advertisementService: AdvertisementService) {}

  @Get()
  async getPublicAdvertisements(@Query() query: PublicAdvertisementQueryDto) {
    return this.advertisementService.getPublicAdvertisements(
      query.placement,
      query.page,
      query.limit,
    );
  }

  @Post(':id/impression')
  async recordImpression(@Param('id') id: string) {
    return this.advertisementService.recordImpression(id);
  }

  @Post(':id/click')
  async recordClick(@Param('id') id: string) {
    return this.advertisementService.recordClick(id);
  }
}
