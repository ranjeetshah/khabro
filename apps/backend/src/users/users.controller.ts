import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
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
import { FollowService } from './follow.service';
import { SuggestionService } from './suggestion.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly moderationService: ModerationService,
    private readonly followService: FollowService,
    private readonly suggestionService: SuggestionService,
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

  @Get('suggestions')
  async getSuggestions(
    @Req() request: Request,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = this.userId(request);
    return this.suggestionService.getSuggestions(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('me/reports')
  async getMyReports(
    @Req() request: Request,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = this.userId(request);
    return this.usersService.getMyReports(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('me/witnesses')
  async getMyWitnesses(
    @Req() request: Request,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = this.userId(request);
    return this.usersService.getMyWitnessHistory(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
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

  @Post(':id/follow')
  async follow(
    @Req() request: Request,
    @Param('id') followingId: string,
  ) {
    const followerId = this.userId(request);
    return this.followService.followUser(followerId, followingId);
  }

  @Delete(':id/follow')
  async unfollow(
    @Req() request: Request,
    @Param('id') followingId: string,
  ) {
    const followerId = this.userId(request);
    return this.followService.unfollowUser(followerId, followingId);
  }

  @Get(':id/follow-status')
  async getFollowStatus(
    @Req() request: Request,
    @Param('id') followingId: string,
  ) {
    const followerId = this.userId(request);
    return this.followService.getFollowStatus(followerId, followingId);
  }

  @Get(':id/followers')
  async getFollowers(
    @Param('id') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.followService.getFollowers(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get(':id/following')
  async getFollowing(
    @Param('id') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.followService.getFollowing(
      userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }
}
