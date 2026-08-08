import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';

import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

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
    });

    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return { user };
  }
}
