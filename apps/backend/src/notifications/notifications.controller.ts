import {
  Controller,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationService } from './notification.service';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
  };
};

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationService: NotificationService) {}

  private userSub(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Get()
  async getNotifications(
    @Req() request: Request,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.notificationService.getForUser(
      this.userSub(request),
      pageNum,
      limitNum,
    );
  }

  @Get('unread-count')
  async getUnreadCount(@Req() request: Request) {
    return this.notificationService.getUnreadCount(this.userSub(request));
  }

  @Patch('read-all')
  async markAllAsRead(@Req() request: Request) {
    return this.notificationService.markAllAsRead(this.userSub(request));
  }

  @Patch(':id/read')
  async markAsRead(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return this.notificationService.markAsRead(this.userSub(request), id);
  }
}
