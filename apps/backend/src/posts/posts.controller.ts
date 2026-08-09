import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreatePostDto } from './dto/create-post.dto';
import { LikesService } from './likes.service';
import { PostsService } from './posts.service';
import { WitnessService } from './witness.service';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
  };
};

@Controller('posts')
@UseGuards(JwtAuthGuard)
export class PostsController {
  constructor(
    private readonly postsService: PostsService,
    private readonly likesService: LikesService,
    private readonly witnessService: WitnessService,
  ) {}

  private userId(request: Request): string {
    return (request as AuthenticatedRequest).user.sub;
  }

  @Post()
  async create(
    @Req() request: Request,
    @Body() dto: CreatePostDto,
  ) {
    return this.postsService.create(
      this.userId(request),
      dto.content,
    );
  }

  @Get('me')
  async findMine(@Req() request: Request) {
    return this.postsService.findMine(
      this.userId(request),
    );
  }

  @Get(':id')
  async findOne(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    const post = await this.postsService.findOne(
      id,
      this.userId(request),
    );

    if (!post) {
      return {
        message: 'Post not found',
      };
    }

    return post;
  }

  @Delete(':id')
  async delete(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return this.postsService.delete(
      this.userId(request),
      id,
    );
  }

  @Post(':id/like')
  async like(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      like: await this.likesService.like(
        this.userId(request),
        id,
      ),
    };
  }

  @Delete(':id/like')
  async unlike(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      like: await this.likesService.unlike(
        this.userId(request),
        id,
      ),
    };
  }

  @Get(':id/likes')
  async getLikes(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      like: await this.likesService.getStatus(
        this.userId(request),
        id,
      ),
    };
  }

  @Post(':id/witness')
  async witness(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      witness: await this.witnessService.witness(
        this.userId(request),
        id,
      ),
    };
  }

  @Delete(':id/witness')
  async unwitness(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      witness: await this.witnessService.unwitness(
        this.userId(request),
        id,
      ),
    };
  }

  @Get(':id/witnesses')
  async getWitnesses(
    @Req() request: Request,
    @Param('id') id: string,
  ) {
    return {
      witness: await this.witnessService.getStatus(
        this.userId(request),
        id,
      ),
    };
  }
}