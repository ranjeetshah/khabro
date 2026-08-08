import {
  Body,
  ConflictException,
  Controller,
  Get,
  NotFoundException,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';

import type { Request } from 'express';

import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { DevLoginDto } from './dto/dev-login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const existingUser = await this.authService.findUserByPhone(dto.phone);

    if (existingUser) {
      throw new ConflictException('A user with this phone already exists');
    }

    const user = await this.authService.createUser(dto.phone, dto.name);
    return this.authService.generateAccessToken(user.id);
  }

  @Post('dev-login')
  async devLogin(@Body() dto: DevLoginDto) {
    const user = await this.authService.findUserByPhone(dto.phone);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.authService.generateAccessToken(user.id);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@Req() request: Request) {
    const userId = request.user?.sub;

    if (!userId) {
      throw new UnauthorizedException();
    }

    const user = await this.authService.findUserById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return { user };
  }
}