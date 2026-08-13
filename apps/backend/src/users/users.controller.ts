import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';

import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateReportDto } from '../moderation/dto/create-report.dto';
import { CreateUserReportDto } from '../moderation/dto/create-user-report.dto';
import { ModerationService } from '../moderation/moderation.service';
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly moderationService: ModerationService,
  ) {}

  private userId(request: Request): string {
    return (request as Request & { user: { sub: string } }).user.sub;
  }

  @Get('me')
  async getMe(@Req() request: Request) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    const user = await this.usersService.findMe(userId);

    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return { user };
  }

  @Patch('me')
  async updateMe(
    @Req() request: Request,
    @Body() dto: UpdateMeDto,
  ) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    const user = await this.usersService.updateMe(userId, {
      ...(dto.name !== undefined && { name: dto.name.trim() }),
      ...(dto.allowCivicComplaintContactSharing !== undefined && {
        allowCivicComplaintContactSharing:
          dto.allowCivicComplaintContactSharing,
      }),
    });

    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return { user };
  }

  @Get(':id/public')
  async getPublic(@Param('id') userId: string) {
    const user = await this.usersService.findPublic(userId);
    if (!user) throw new NotFoundException('Public user not found');
    return { user };
  }

  @Post(':id/report')
  async reportUser(
    @Req() request: Request,
    @Param('id') id: string,
    @Body() dto: CreateUserReportDto,
  ) {
    return this.moderationService.createUserReport(
      this.userId(request),
      id,
      dto.reason,
      dto.description,
    );
  }
}
