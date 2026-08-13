import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';

@Controller('conversations')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post()
  async createConversation(
    @Req() request: Request,
    @Body('userId') targetUserId: string,
  ) {
    const userId = request.user!.sub;
    return this.chatService.createConversation(userId, targetUserId);
  }

  @Get()
  async listConversations(
    @Req() request: Request,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = request.user!.sub;
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.chatService.listConversations(userId, pageNum, limitNum);
  }

  @Get('unread-count')
  async getGlobalUnreadCount(@Req() request: Request) {
    const userId = request.user!.sub;
    return this.chatService.getGlobalUnreadCount(userId);
  }

  @Get(':id')
  async getConversationDetail(
    @Req() request: Request,
    @Param('id') conversationId: string,
  ) {
    const userId = request.user!.sub;
    return this.chatService.getConversationDetail(userId, conversationId);
  }

  @Post(':id/messages')
  async sendMessage(
    @Req() request: Request,
    @Param('id') conversationId: string,
    @Body('content') content: string,
    @Body('clientMessageId') clientMessageId?: string,
  ) {
    const userId = request.user!.sub;
    return this.chatService.sendMessage(
      userId,
      conversationId,
      content,
      clientMessageId,
    );
  }

  @Get(':id/messages')
  async listMessages(
    @Req() request: Request,
    @Param('id') conversationId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const userId = request.user!.sub;
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.chatService.listMessages(userId, conversationId, pageNum, limitNum);
  }

  @Patch(':id/read')
  async markAsRead(
    @Req() request: Request,
    @Param('id') conversationId: string,
  ) {
    const userId = request.user!.sub;
    return this.chatService.markAsRead(userId, conversationId);
  }

  @Delete(':conversationId/messages/:messageId')
  async deleteMessage(
    @Req() request: Request,
    @Param('conversationId') conversationId: string,
    @Param('messageId') messageId: string,
  ) {
    const userId = request.user!.sub;
    return this.chatService.deleteMessage(userId, conversationId, messageId);
  }
}
