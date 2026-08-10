import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../database/database.service';
import { VerificationStatus } from '../generated/prisma/enums';

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
  ) {}

  /** Safe public metadata only — status plus witness count, no private rows. */
  async getVerificationStatus(postId: string) {
    const post = await this.assertActivePost(postId);
    const witnessCount = await this.database.witness.count({
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
   * the count.
   */
  async evaluatePost(postId: string) {
    const post = await this.assertActivePost(postId);
    const witnessCount = await this.database.witness.count({
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
      await this.database.post.update({
        where: { id: postId },
        data: { verificationStatus: next },
      });
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

  private async assertActivePost(postId: string) {
    const post = await this.database.post.findFirst({
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
