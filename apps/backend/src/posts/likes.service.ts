import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class LikesService {
  constructor(private readonly database: DatabaseService) {}

  async like(userId: string, postId: string) {
    await this.assertPostExists(postId);
    await this.database.like.upsert({
      where: { userId_postId: { userId, postId } },
      create: { userId, postId },
      update: {},
    });
    return this.status(userId, postId);
  }

  async unlike(userId: string, postId: string) {
    await this.assertPostExists(postId);
    await this.database.like.deleteMany({ where: { userId, postId } });
    return this.status(userId, postId);
  }

  async getStatus(userId: string, postId: string) {
    await this.assertPostExists(postId);
    return this.status(userId, postId);
  }

  private async assertPostExists(postId: string) {
    const post = await this.database.post.findFirst({
      where: { id: postId, deletedAt: null },
      select: { id: true },
    });
    if (!post) throw new NotFoundException('Post not found');
  }

  private async status(userId: string, postId: string) {
    const [likeCount, liked] = await Promise.all([
      this.database.like.count({ where: { postId } }),
      this.database.like.findFirst({
        where: { postId, userId },
        select: { id: true },
      }),
    ]);
    return { likeCount, likedByMe: liked !== null };
  }
}
