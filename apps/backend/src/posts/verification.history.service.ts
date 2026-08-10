import { Injectable, NotFoundException } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '../generated/prisma/client';
import {
  VerificationContributionType,
  VerificationEventType,
  VerificationStatus,
} from '../generated/prisma/enums';

/**
 * Owns verification event/contribution records for posts.
 *
 * Events are the public-facing, privacy-safe history of a post's
 * verification journey. Contributions are the internal, identity-free ledger
 * that a future Trust System can consume without depending on Witness or
 * verification internals. Both are written transaction-safely so a failed or
 * duplicate operation never leaks a phantom history entry.
 */
@Injectable()
export class VerificationHistoryService {
  constructor(private readonly database: DatabaseService) {}

  async recordPostCreated(postId: string, client?: Prisma.TransactionClient) {
    const db = client ?? this.database;
    await db.verificationEvent.create({
      data: {
        postId,
        type: VerificationEventType.POST_CREATED,
        toStatus: VerificationStatus.REPORTED,
      },
    });
  }

  async recordWitnessAdded(postId: string, client?: Prisma.TransactionClient) {
    const db = client ?? this.database;
    await db.verificationEvent.create({
      data: {
        postId,
        type: VerificationEventType.WITNESS_ADDED,
      },
    });
  }

  async recordWitnessRemoved(
    postId: string,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    await db.verificationEvent.create({
      data: {
        postId,
        type: VerificationEventType.WITNESS_REMOVED,
      },
    });
  }

  async recordWitnessContribution(
    postId: string,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    await db.verificationContribution.create({
      data: {
        postId,
        type: VerificationContributionType.WITNESS,
      },
    });
  }

  async recordStatusChanged(
    postId: string,
    fromStatus: VerificationStatus,
    toStatus: VerificationStatus,
    client?: Prisma.TransactionClient,
  ) {
    if (client) {
      await client.verificationEvent.create({
        data: {
          postId,
          type: VerificationEventType.STATUS_CHANGED,
          fromStatus,
          toStatus,
        },
      });
      await client.verificationContribution.create({
        data: {
          postId,
          type: VerificationContributionType.STATUS_TRANSITION,
        },
      });
      return;
    }

    await this.database.$transaction([
      this.database.verificationEvent.create({
        data: {
          postId,
          type: VerificationEventType.STATUS_CHANGED,
          fromStatus,
          toStatus,
        },
      }),
      this.database.verificationContribution.create({
        data: {
          postId,
          type: VerificationContributionType.STATUS_TRANSITION,
        },
      }),
    ]);
  }

  /**
   * Returns the privacy-safe verification history for a post. Only event
   * metadata is exposed — never userId, witness identity, phone, locality, or
   * coordinates — ordered oldest first (createdAt ASC, then id ASC for
   * stability when timestamps collide).
   */
  async getHistory(postId: string) {
    await this.assertActivePost(postId);

    const events = await this.database.verificationEvent.findMany({
      where: { postId },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: {
        type: true,
        fromStatus: true,
        toStatus: true,
        createdAt: true,
      },
    });

    return {
      events: events.map((event) => ({
        type: event.type,
        ...(event.fromStatus === null ? {} : { fromStatus: event.fromStatus }),
        ...(event.toStatus === null ? {} : { toStatus: event.toStatus }),
        createdAt: event.createdAt,
      })),
    };
  }

  private async assertActivePost(postId: string) {
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

    return post;
  }
}
