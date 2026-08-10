import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '../generated/prisma/client';
import { VerificationStatus } from '../generated/prisma/enums';
import { VerificationHistoryService } from './verification.history.service';

const DEFAULT_LOCAL_VERIFICATION_THRESHOLD = 2;

/**
 * Owns verification state transitions for posts.
 *
 * Verification is a backend-owned state/event decision, never a client
 * controlled field and never a live counter label. Once a post reaches
 * LOCALLY_VERIFIED it is not downgraded automatically when witnesses
 * are later removed.
 */
@Injectable()
export class VerificationService {
  constructor(
    private readonly database: DatabaseService,
    private readonly config: ConfigService,
    private readonly verificationHistory: VerificationHistoryService,
  ) {}

  /** Safe public metadata only — status plus witness count, no private rows. */
  async getVerificationStatus(
    postId: string,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    const post = await this.assertActivePost(postId, db);
    const witnessCount = await db.witness.count({
      where: { postId },
    });

    return {
      status: post.verificationStatus,
      witnessCount,
    };
  }

  /**
   * Evaluates and, if needed, advances the post's verification state.
   *
   * REPORTED -> UNDER_VERIFICATION once the first valid witness exists.
   * UNDER_VERIFICATION -> LOCALLY_VERIFIED once the configured threshold is met.
   *
   * Only actual Witness records count; the author is not auto-witnessed and
   * the unique (userId, postId) constraint prevents duplicates from inflating
   * the count. When a transition actually occurs it is recorded as a
   * STATUS_CHANGED event plus a STATUS_TRANSITION contribution, always inside
   * the caller's transaction when one is supplied.
   */
  async evaluatePost(postId: string, client?: Prisma.TransactionClient) {
    const db = client ?? this.database;
    const post = await this.assertActivePost(postId, db);
    const witnessCount = await db.witness.count({
      where: { postId },
    });

    const current = post.verificationStatus;
    let next = current;

    if (current === VerificationStatus.REPORTED && witnessCount >= 1) {
      next = VerificationStatus.UNDER_VERIFICATION;
    }

    if (
      current === VerificationStatus.UNDER_VERIFICATION &&
      witnessCount >= this.localVerificationThreshold()
    ) {
      next = VerificationStatus.LOCALLY_VERIFIED;
    }

    if (next !== current) {
      await db.post.update({
        where: { id: postId },
        data: { verificationStatus: next },
      });
      await this.verificationHistory.recordStatusChanged(
        postId,
        current,
        next,
        client,
      );
    }

    return {
      status: next,
      witnessCount,
    };
  }

  private localVerificationThreshold(): number {
    const raw = this.config.get<string>('LOCAL_VERIFICATION_WITNESS_THRESHOLD');
    const parsed = raw === undefined ? NaN : Number(raw);
    return Number.isFinite(parsed) && parsed >= 1
      ? parsed
      : DEFAULT_LOCAL_VERIFICATION_THRESHOLD;
  }

  private async assertActivePost(
    postId: string,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    const post = await db.post.findFirst({
      where: {
        id: postId,
        deletedAt: null,
      },
      select: {
        id: true,
        verificationStatus: true,
      },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    return post;
  }
}
