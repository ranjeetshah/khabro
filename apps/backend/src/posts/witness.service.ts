import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class WitnessService {
  constructor(private readonly database: DatabaseService) {}

  async witness(userId: string, postId: string) {
    await this.assertPostExists(postId);

    await this.database.witness.upsert({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
      create: {
        userId,
        postId,
      },
      update: {},
    });

    return this.status(userId, postId);
  }

  async unwitness(userId: string, postId: string) {
    await this.assertPostExists(postId);

    await this.database.witness.deleteMany({
      where: {
        userId,
        postId,
      },
    });

    return this.status(userId, postId);
  }

  async getStatus(userId: string, postId: string) {
    await this.assertPostExists(postId);

    return this.status(userId, postId);
  }

  private async assertPostExists(postId: string) {
    const post = await this.database.post.findFirst({
      where: {
        id: postId,
        deletedAt: null,
      },
      select: {
        id: true,
      },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }
  }

  private async status(userId: string, postId: string) {
    const [witnessCount, witnessed] = await Promise.all([
      this.database.witness.count({
        where: { postId },
      }),
      this.database.witness.findFirst({
        where: {
          postId,
          userId,
        },
        select: {
          id: true,
        },
      }),
    ]);

    return {
      witnessCount,
      witnessedByMe: witnessed !== null,
    };
  }
}