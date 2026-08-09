import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

const POST_SELECT = {
  id: true,
  authorId: true,
  localityId: true,
  content: true,
  createdAt: true,
  updatedAt: true,
} as const;

@Injectable()
export class PostsService {
  constructor(private readonly database: DatabaseService) {}

  async create(authorId: string, content: string) {
    const location = await this.database.userLocation.findUnique({
      where: { userId: authorId },
      select: { localityId: true },
    });

    return this.database.post.create({
      data: {
        authorId,
        localityId: location?.localityId ?? null,
        content: content.trim(),
      },
      select: POST_SELECT,
    });
  }

  async findMine(authorId: string) {
    return this.database.post.findMany({
      where: { authorId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: POST_SELECT,
    });
  }

  async findOne(id: string) {
    return this.database.post.findFirst({
      where: { id, deletedAt: null },
      select: POST_SELECT,
    });
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
