import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateFeedbackDto } from './dto/create-feedback.dto';
import { FeedbackQueryDto } from './dto/feedback-query.dto';
import { FeedbackService } from './feedback.service';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
  };
};

@Controller('feedback')
@UseGuards(JwtAuthGuard)
export class FeedbackController {
  constructor(private readonly feedbackService: FeedbackService) {}

  private userId(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Post()
  async create(@Req() request: Request, @Body() dto: CreateFeedbackDto) {
    const feedback = await this.feedbackService.create(
      this.userId(request),
      dto,
    );

    return {
      id: feedback.id,
      type: feedback.type,
      status: feedback.status,
      createdAt: feedback.createdAt,
    };
  }

  @Get('me')
  async getMine(@Req() request: Request, @Query() query: FeedbackQueryDto) {
    return this.feedbackService.getMyFeedback(
      this.userId(request),
      query.page,
      query.limit,
    );
  }
}
