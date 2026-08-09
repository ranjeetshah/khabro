import { BadRequestException, Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { PUBLIC_USER_SELECT } from '../users/public-user.select';

const FEED_POST_SELECT = {
  id: true,
  authorId: true,
  content: true,
  createdAt: true,
  updatedAt: true,
  author: { select: PUBLIC_USER_SELECT },
} as const;

type FeedCursor = { createdAt: string; id: string };

@Injectable()
export class FeedService {
  constructor(private readonly database: DatabaseService) {}

  async getFeed(userId: string, limit: number, cursor?: string) {
    const location = await this.database.userLocation.findUnique({
      where: { userId },
      select: { localityId: true },
    });

    if (!location?.localityId) {
      return { items: [], nextCursor: null };
    }

    const decodedCursor = cursor ? this.decodeCursor(cursor) : null;
    const posts = await this.database.post.findMany({
      where: {
        localityId: location.localityId,
        deletedAt: null,
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
      select: FEED_POST_SELECT,
    });

    const hasNextPage = posts.length > limit;
    const items = hasNextPage ? posts.slice(0, limit) : posts;
    const lastItem = items.at(-1);

    return {
      items,
      nextCursor:
        hasNextPage && lastItem
          ? this.encodeCursor({
              createdAt: lastItem.createdAt.toISOString(),
              id: lastItem.id,
            })
          : null,
    };
  }

  private encodeCursor(cursor: FeedCursor) {
    return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64');
  }

  private decodeCursor(cursor: string): FeedCursor {
    let decoded: Partial<FeedCursor>;
    try {
      decoded = JSON.parse(
        Buffer.from(cursor, 'base64').toString('utf8'),
      ) as Partial<FeedCursor>;
    } catch {
      throw new BadRequestException('Invalid feed cursor');
    }

    if (
      typeof decoded.createdAt !== 'string' ||
      typeof decoded.id !== 'string' ||
      Number.isNaN(new Date(decoded.createdAt).getTime()) ||
      decoded.id.length === 0
    ) {
      throw new BadRequestException('Invalid feed cursor');
    }

    return { createdAt: decoded.createdAt, id: decoded.id };
  }
}
