import { PUBLIC_USER_SELECT } from '../users/public-user.select';

export const postMediaSelect = {
  id: true,
  type: true,
  provider: true,
  mediaUrl: true,
  thumbnailUrl: true,
  providerMediaId: true,
  mimeType: true,
  width: true,
  height: true,
  durationSeconds: true,
  processingStatus: true,
  sortOrder: true,
};

export const postSelect = (userId: string) => ({
  id: true,
  authorId: true,
  content: true,
  category: true,
  background: true,
  linkUrl: true,
  verificationStatus: true,
  createdAt: true,
  updatedAt: true,
  author: { select: PUBLIC_USER_SELECT },
  media: {
    select: postMediaSelect,
    orderBy: { sortOrder: 'asc' as const },
  },
  _count: {
    select: {
      likes: true,
      comments: {
        where: {
          status: 'ACTIVE' as const,
          deletedAt: null,
        },
      },
    },
  },
  likes: {
    where: { userId },
    select: { id: true },
    take: 1,
  },
});

export function toPostResponse(post: any) {
  if (!post) return null;
  const { _count, likes, media, ...safePost } = post;

  const formattedMedia = Array.isArray(media)
    ? media.map((item: any) => ({
        id: item.id,
        type: item.type,
        provider: item.provider,
        url: item.mediaUrl,
        thumbnailUrl: item.thumbnailUrl ?? null,
        providerMediaId: item.providerMediaId ?? null,
        mimeType: item.mimeType ?? null,
        width: item.width ?? null,
        height: item.height ?? null,
        durationSeconds: item.durationSeconds ?? null,
        processingStatus: item.processingStatus,
        sortOrder: item.sortOrder ?? 0,
      }))
    : [];

  return {
    ...safePost,
    background: safePost.background ?? 'DEFAULT',
    linkUrl: safePost.linkUrl ?? null,
    media: formattedMedia,
    likeCount: _count?.likes ?? 0,
    commentCount: _count?.comments ?? 0,
    likedByMe: Array.isArray(likes) && likes.length > 0,
  };
}
