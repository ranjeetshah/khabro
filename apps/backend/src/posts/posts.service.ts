import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { postSelect, toPostResponse } from './post.select';

@Injectable()
export class PostsService {
  constructor(private readonly database: DatabaseService) {}

  async create(authorId: string, content: string) {
    const location = await this.database.userLocation.findUnique({
      where: { userId: authorId },
      select: { localityId: true },
    });

    const post = await this.database.post.create({
      data: {
        authorId,
        localityId: location?.localityId ?? null,
        content: content.trim(),
      },
      select: postSelect(authorId),
    });
    return toPostResponse(post);
  }

  async findMine(authorId: string) {
    const posts = await this.database.post.findMany({
      where: { authorId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: postSelect(authorId),
    });
    return posts.map(toPostResponse);
  }

  async findOne(id: string, userId = '') {
    const post = await this.database.post.findFirst({
      where: { id, deletedAt: null },
      select: postSelect(userId),
    });
    return post ? toPostResponse(post) : null;
  }

  async delete(authorId: string, id: string) {
    const post = await this.database.post.findFirst({
      where: { id, deletedAt: null },
      select: { authorId: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== authorId) {
      throw new ForbiddenException('Only the author can delete this post');
    }

    await this.database.post.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { id };
  }
}
