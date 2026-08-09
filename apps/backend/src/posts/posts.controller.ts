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
import { LikesService } from './likes.service';

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class PostsController {
  constructor(
    private readonly postsService: PostsService,
    private readonly likesService: LikesService,
  ) {}

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
  async getOne(@Req() request: Request, @Param('id') id: string) {
    const post = await this.postsService.findOne(id, this.userId(request));
    if (!post) throw new NotFoundException('Post not found');
    return { post };
  }

  @Delete(':id')
  async remove(@Req() request: Request, @Param('id') id: string) {
    return { post: await this.postsService.delete(this.userId(request), id) };
  }

  @PostMethod(':id/like')
  async like(@Req() request: Request, @Param('id') id: string) {
    return {
      like: await this.likesService.like(this.userId(request), id),
    };
  }

  @Delete(':id/like')
  async unlike(@Req() request: Request, @Param('id') id: string) {
    return {
      like: await this.likesService.unlike(this.userId(request), id),
    };
  }

  @Get(':id/likes')
  async getLikes(@Req() request: Request, @Param('id') id: string) {
    return {
      like: await this.likesService.getStatus(this.userId(request), id),
    };
  }

  private userId(request: Request) {
    const userId = request.user?.sub;
    if (!userId) throw new UnauthorizedException();
    return userId;
  }
}
