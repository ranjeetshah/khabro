import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ReportCommentDto } from './dto/report-comment.dto';

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Get(':id/comments')
  async listComments(
    @Param('id') postId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;

    return this.commentsService.listComments(
      postId,
      isNaN(pageNum) ? 1 : pageNum,
      isNaN(limitNum) ? 20 : limitNum,
    );
  }

  @Post(':id/comments')
  async createComment(
    @Req() req: any,
    @Param('id') postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    const userId = req.user.sub;
    return this.commentsService.createComment(userId, postId, dto);
  }

  @Delete(':postId/comments/:commentId')
  async deleteComment(
    @Req() req: any,
    @Param('postId') postId: string,
    @Param('commentId') commentId: string,
  ) {
    const userId = req.user.sub;
    return this.commentsService.deleteComment(userId, postId, commentId);
  }

  @Post(':postId/comments/:commentId/report')
  async reportComment(
    @Req() req: any,
    @Param('postId') postId: string,
    @Param('commentId') commentId: string,
    @Body() dto: ReportCommentDto,
  ) {
    const userId = req.user.sub;
    return this.commentsService.reportComment(userId, postId, commentId, dto);
  }
}
