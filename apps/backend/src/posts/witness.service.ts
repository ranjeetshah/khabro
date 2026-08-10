import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { VerificationService } from './verification.service';

@Injectable()
export class WitnessService {
  constructor(
    private readonly database: DatabaseService,
    private readonly verificationService: VerificationService,
  ) {}

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

    const verification = await this.verificationService.evaluatePost(postId);
    const status = await this.status(userId, postId);

    return {
      ...status,
      verification,
    };
  }

  async unwitness(userId: string, postId: string) {
    await this.assertPostExists(postId);

    await this.database.witness.deleteMany({
      where: {
        userId,
        postId,
      },
    });

    const status = await this.status(userId, postId);

    return {
      ...status,
      verification:
        await this.verificationService.getVerificationStatus(postId),
    };
  }

  async getStatus(userId: string, postId: string) {
    await this.assertPostExists(postId);

    const status = await this.status(userId, postId);

    return {
      ...status,
      verification:
        await this.verificationService.getVerificationStatus(postId),
    };
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
