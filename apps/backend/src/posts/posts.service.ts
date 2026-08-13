import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { PostCategory, VerificationStatus } from '../generated/prisma/enums';
import { SearchPostsDto } from './dto/search-posts.dto';
import { postSelect, toPostResponse } from './post.select';
import { VerificationHistoryService } from './verification.history.service';

@Injectable()
export class PostsService {
  constructor(
    private readonly database: DatabaseService,
    private readonly verificationHistory: VerificationHistoryService,
  ) {}

  async create(authorId: string, content: string, category?: PostCategory) {
    const location = await this.database.userLocation.findUnique({
      where: { userId: authorId },
      select: { localityId: true },
    });

    const post = await this.database.$transaction(async (tx) => {
      const created = await tx.post.create({
        data: {
          authorId,
          localityId: location?.localityId ?? null,
          content: content.trim(),
          category: category ?? PostCategory.GENERAL,
        },
        select: postSelect(authorId),
      });

      await this.verificationHistory.recordPostCreated(created.id, tx);

      return created;
    });
    return toPostResponse(post);
  }

  async findMine(authorId: string) {
    const posts = await this.database.post.findMany({
      where: { authorId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: postSelect(authorId),
    });
    return posts.map(toPostResponse);
  }

  async findOne(id: string, userId = '') {
    const post = await this.database.post.findFirst({
      where: { id, deletedAt: null },
      select: postSelect(userId),
    });
    return post ? toPostResponse(post) : null;
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

  async search(userId: string, dto: SearchPostsDto) {
    const page = Math.max(1, dto.page ?? 1);
    const limit = Math.min(50, Math.max(1, dto.limit ?? 20));
    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null,
    };

    if (dto.q && dto.q.trim().length > 0) {
      where.content = {
        contains: dto.q.trim(),
        mode: 'insensitive',
      };
    }

    if (dto.category) {
      where.category = dto.category;
    }

    if (dto.verified === true) {
      where.verificationStatus = VerificationStatus.LOCALLY_VERIFIED;
    } else if (dto.verified === false) {
      where.verificationStatus = {
        in: [
          VerificationStatus.REPORTED,
          VerificationStatus.UNDER_VERIFICATION,
        ],
      };
    }

    if (dto.recent === true) {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      where.createdAt = { gte: sevenDaysAgo };
    }

    if (dto.radiusKm && dto.radiusKm > 0) {
      const userLoc = await this.database.userLocation.findUnique({
        where: { userId },
        select: { localityId: true },
      });
      if (userLoc?.localityId) {
        where.localityId = userLoc.localityId;
      }
    }

    const posts = await this.database.post.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip,
      take: limit + 1,
      select: postSelect(userId),
    });

    const hasNextPage = posts.length > limit;
    const items = (hasNextPage ? posts.slice(0, limit) : posts).map(
      toPostResponse,
    );

    return {
      items,
      page,
      limit,
      hasNextPage,
    };
  }
}
