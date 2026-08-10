import { PUBLIC_USER_SELECT } from '../users/public-user.select';

export const postSelect = (userId: string) => ({
  id: true,
  authorId: true,
  content: true,
  verificationStatus: true,
  createdAt: true,
  updatedAt: true,
  author: { select: PUBLIC_USER_SELECT },
  _count: { select: { likes: true } },
  likes: {
    where: { userId },
    select: { id: true },
    take: 1,
  },
});

export function toPostResponse(post: any) {
  const { _count, likes, ...safePost } = post;
  return {
    ...safePost,
    likeCount: _count?.likes ?? 0,
    likedByMe: Array.isArray(likes) && likes.length > 0,
  };
}
