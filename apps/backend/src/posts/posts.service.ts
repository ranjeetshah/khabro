import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import {
  PostBackground,
  PostCategory,
  PostMediaType,
  VerificationStatus,
} from '../generated/prisma/enums';
import { CreatePostDto, isValidLinkUrl } from './dto/create-post.dto';
import { SearchPostsDto } from './dto/search-posts.dto';
import { postSelect, toPostResponse } from './post.select';
import { VerificationHistoryService } from './verification.history.service';

@Injectable()
export class PostsService {
  constructor(
    private readonly database: DatabaseService,
    private readonly verificationHistory: VerificationHistoryService,
  ) {}

  async create(authorId: string, dto: CreatePostDto) {
    if (dto.linkUrl && !isValidLinkUrl(dto.linkUrl)) {
      throw new BadRequestException('Invalid link URL');
    }

    const location = await this.database.userLocation.findUnique({
      where: { userId: authorId },
      select: { localityId: true },
    });

    let verifiedMedia: any[] = [];
    if (dto.mediaIds && dto.mediaIds.length > 0) {
      verifiedMedia = await this.database.postMedia.findMany({
        where: { id: { in: dto.mediaIds } },
      });

      if (verifiedMedia.length !== dto.mediaIds.length) {
        throw new NotFoundException('One or more media assets not found');
      }

      for (const media of verifiedMedia) {
        if (media.createdById !== authorId) {
          throw new ForbiddenException(
            'Cannot attach media assets created by another user',
          );
        }
      }

      const images = verifiedMedia.filter((m) => m.type === PostMediaType.IMAGE);
      const videos = verifiedMedia.filter((m) => m.type === PostMediaType.VIDEO);

      if (images.length > 0 && videos.length > 0) {
        throw new BadRequestException(
          'A post cannot contain both images and video',
        );
      }

      if (images.length > 4) {
        throw new BadRequestException('Maximum 4 images allowed per post');
      }

      if (videos.length > 1) {
        throw new BadRequestException('Maximum 1 video allowed per post');
      }
    }

    // Hard-color background is only allowed for text-only posts
    const hasMedia = verifiedMedia.length > 0;
    const finalBackground = hasMedia
      ? PostBackground.DEFAULT
      : (dto.background ?? PostBackground.DEFAULT);

    const post = await this.database.$transaction(async (tx) => {
      const created = await tx.post.create({
        data: {
          authorId,
          localityId: location?.localityId ?? null,
          content: dto.content.trim(),
          category: dto.category ?? PostCategory.GENERAL,
          background: finalBackground,
          linkUrl: dto.linkUrl ? dto.linkUrl.trim() : null,
        },
      });

      if (dto.mediaIds && dto.mediaIds.length > 0) {
        for (let i = 0; i < dto.mediaIds.length; i++) {
          const mediaId = dto.mediaIds[i];
          await tx.postMedia.update({
            where: { id: mediaId },
            data: {
              postId: created.id,
              sortOrder: i,
            },
          });
        }
      }

      await this.verificationHistory.recordPostCreated(created.id, tx);

      return tx.post.findUnique({
        where: { id: created.id },
        select: postSelect(authorId),
      });
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
