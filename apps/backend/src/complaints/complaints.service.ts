import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '../generated/prisma/client';
import { ComplaintStatus } from '../generated/prisma/enums';

const DEFAULT_COMPLAINT_PAGE_SIZE = 20;

type ComplaintCursor = { createdAt: string; id: string };

/**
 * Owns civic complaints. A complaint is a formal submission tied to a
 * LOCALLY_VERIFIED post; the backend re-checks authoritative post state and
 * never trusts a client-supplied verification badge. Only SUBMITTED is
 * publicly creatable — later statuses belong to a future authority workflow.
 */
@Injectable()
export class ComplaintService {
  constructor(private readonly database: DatabaseService) {}

  async create(userId: string, postId: string, description: string) {
    const post = await this.database.post.findFirst({
      where: { id: postId, deletedAt: null },
      select: { id: true, verificationStatus: true },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.verificationStatus !== 'LOCALLY_VERIFIED') {
      throw new ConflictException(
        'Only locally verified posts can be submitted as civic complaints',
      );
    }

    const existing = await this.database.complaint.findUnique({
      where: {
        postId_createdById: {
          postId,
          createdById: userId,
        },
      },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException(
        'You already submitted a complaint for this post',
      );
    }

    const complaint = await this.database.$transaction(async (tx) => {
      const created = await tx.complaint.create({
        data: {
          postId,
          createdById: userId,
          description: description.trim(),
        },
        select: { id: true, status: true },
      });

      await tx.complaintStatusHistory.create({
        data: {
          complaintId: created.id,
          toStatus: ComplaintStatus.SUBMITTED,
        },
      });

      return created;
    });

    return { id: complaint.id, status: complaint.status };
  }

  async findOne(id: string, userId: string) {
    const complaint = await this.database.complaint.findFirst({
      where: { id },
      select: {
        id: true,
        createdById: true,
        status: true,
        description: true,
        createdAt: true,
        updatedAt: true,
        post: {
          select: {
            content: true,
            verificationStatus: true,
          },
        },
        statusHistory: {
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
          select: {
            fromStatus: true,
            toStatus: true,
            createdAt: true,
          },
        },
      },
    });

    if (!complaint) {
      throw new NotFoundException('Complaint not found');
    }

    if (complaint.createdById !== userId) {
      throw new NotFoundException('Complaint not found');
    }

    const { createdById, ...safe } = complaint;
    return safe;
  }

  async findMine(userId: string, limit: number, cursor?: string) {
    const decodedCursor = cursor ? this.decodeCursor(cursor) : null;
    const complaints = await this.database.complaint.findMany({
      where: {
        createdById: userId,
        ...(decodedCursor && {
          OR: [
            { createdAt: { lt: new Date(decodedCursor.createdAt) } },
            {
              createdAt: new Date(decodedCursor.createdAt),
              id: { lt: decodedCursor.id },
            },
          ],
        }),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: {
        id: true,
        status: true,
        description: true,
        createdAt: true,
      },
    });

    const hasNextPage = complaints.length > limit;
    const items = (hasNextPage ? complaints.slice(0, limit) : complaints).map(
      (complaint) => ({
        id: complaint.id,
        status: complaint.status,
        description: complaint.description,
        createdAt: complaint.createdAt,
      }),
    );
    const lastItem = items.at(-1);

    return {
      complaints: items,
      nextCursor:
        hasNextPage && lastItem
          ? this.encodeCursor({
              createdAt: lastItem.createdAt.toISOString(),
              id: lastItem.id,
            })
          : null,
    };
  }

  /** Internal transition helper for future authority workflows. */
  async transition(
    complaintId: string,
    toStatus: ComplaintStatus,
    client?: Prisma.TransactionClient,
  ) {
    const db = client ?? this.database;
    const complaint = await db.complaint.findUnique({
      where: { id: complaintId },
      select: { id: true, status: true },
    });

    if (!complaint) {
      throw new NotFoundException('Complaint not found');
    }

    if (complaint.status === toStatus) {
      throw new ConflictException('Complaint is already in this status');
    }

    const updated = await db.complaint.update({
      where: { id: complaintId },
      data: { status: toStatus },
      select: { id: true, status: true },
    });

    await db.complaintStatusHistory.create({
      data: {
        complaintId,
        fromStatus: complaint.status,
        toStatus,
      },
    });

    return updated;
  }

  private encodeCursor(cursor: ComplaintCursor) {
    return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64');
  }

  private decodeCursor(cursor: string): ComplaintCursor {
    let decoded: Partial<ComplaintCursor>;
    try {
      decoded = JSON.parse(
        Buffer.from(cursor, 'base64').toString('utf8'),
      ) as Partial<ComplaintCursor>;
    } catch {
      throw new ConflictException('Invalid complaint cursor');
    }

    if (
      typeof decoded.createdAt !== 'string' ||
      typeof decoded.id !== 'string' ||
      Number.isNaN(new Date(decoded.createdAt).getTime()) ||
      decoded.id.length === 0
    ) {
      throw new ConflictException('Invalid complaint cursor');
    }

    return { createdAt: decoded.createdAt, id: decoded.id };
  }

  static readonly DEFAULT_PAGE_SIZE = DEFAULT_COMPLAINT_PAGE_SIZE;
}
