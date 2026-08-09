import {
  Controller,
  Get,
  Query,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FeedQueryDto } from './dto/feed-query.dto';
import { FeedService } from './feed.service';

@Controller('feed')
@UseGuards(JwtAuthGuard)
export class FeedController {
  constructor(private readonly feedService: FeedService) {}

  @Get()
  async getFeed(@Req() request: Request, @Query() query: FeedQueryDto) {
    const userId = request.user?.sub;
    if (!userId) throw new UnauthorizedException();

    return this.feedService.getFeed(userId, query.limit, query.cursor);
  }
}
