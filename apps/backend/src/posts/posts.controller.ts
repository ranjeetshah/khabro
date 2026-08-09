import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post as PostMethod,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreatePostDto } from './dto/create-post.dto';
import { PostsService } from './posts.service';

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @PostMethod()
  async create(@Req() request: Request, @Body() dto: CreatePostDto) {
    const authorId = this.userId(request);
    return { post: await this.postsService.create(authorId, dto.content) };
  }

  @Get('me')
  async getMine(@Req() request: Request) {
    return { posts: await this.postsService.findMine(this.userId(request)) };
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    const post = await this.postsService.findOne(id);
    if (!post) throw new NotFoundException('Post not found');
    return { post };
  }

  @Delete(':id')
  async remove(@Req() request: Request, @Param('id') id: string) {
    return { post: await this.postsService.delete(this.userId(request), id) };
  }

  private userId(request: Request) {
    const userId = request.user?.sub;
    if (!userId) throw new UnauthorizedException();
    return userId;
  }
}
