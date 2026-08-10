import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '../generated/prisma/client';
import { VerificationHistoryService } from './verification.history.service';
import { VerificationService } from './verification.service';

@Injectable()
export class WitnessService {
  constructor(
    private readonly database: DatabaseService,
    private readonly verificationService: VerificationService,
    private readonly verificationHistory: VerificationHistoryService,
  ) {}

  async witness(userId: string, postId: string) {
    await this.assertPostExists(postId);

    return this.database.$transaction(async (tx) => {
      const existing = await tx.witness.findUnique({
        where: {
          userId_postId: {
            userId,
            postId,
          },
        },
        select: {
          id: true,
        },
      });

      if (!existing) {
        await tx.witness.create({
          data: {
            userId,
            postId,
          },
        });

        await this.verificationHistory.recordWitnessAdded(postId, tx);
        await this.verificationHistory.recordWitnessContribution(postId, tx);
      }

      const verification = await this.verificationService.evaluatePost(
        postId,
        tx,
      );
      const status = await this.status(userId, postId, tx);

      return {
        ...status,
        verification,
      };
    });
  }

  async unwitness(userId: string, postId: string) {
    await this.assertPostExists(postId);

    return this.database.$transaction(async (tx) => {
      const removed = await tx.witness.deleteMany({
        where: {
          userId,
          postId,
        },
      });

      if (removed.count > 0) {
        await this.verificationHistory.recordWitnessRemoved(postId, tx);
      }

      const status = await this.status(userId, postId, tx);

      return {
        ...status,
        verification: await this.verificationService.getVerificationStatus(
          postId,
          tx,
        ),
      };
    });
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

  private async status(
    userId: string,
    postId: string,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    const [witnessCount, witnessed] = await Promise.all([
      db.witness.count({
        where: { postId },
      }),
      db.witness.findFirst({
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
