import {
  Body,
  Controller,
  Get,
  Put,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateLocationDto } from './dto/update-location.dto';
import type { Locality } from './locality/locality-resolver';
import { LocationService } from './location.service';

@Controller('location')
@UseGuards(JwtAuthGuard)
export class LocationController {
  constructor(private readonly locationService: LocationService) {}

  @Get('me')
  async getMe(@Req() request: Request) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    return { location: await this.locationService.findMe(userId) };
  }

  @Put('me')
  async updateMe(@Req() request: Request, @Body() dto: UpdateLocationDto) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    const location = await this.locationService.updateMe(userId, dto);
    return { location };
  }

  @Get('me/locality')
  async getMyLocality(@Req() request: Request) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    const locality = await this.locationService.findMyLocality(userId);
    return { locality: locality ? this.toPublicLocality(locality) : null };
  }

  private toPublicLocality(locality: Locality) {
    return {
      id: locality.id,
      name: locality.name,
      city: locality.city,
      state: locality.state,
      country: locality.country,
    };
  }
}
