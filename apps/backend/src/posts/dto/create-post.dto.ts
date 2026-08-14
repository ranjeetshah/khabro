import {
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { PostBackground, PostCategory } from '../../generated/prisma/enums';

export const POST_CONTENT_MAX_LENGTH = 5000;

export function isValidLinkUrl(url?: string): boolean {
  if (!url) return true;
  const trimmed = url.trim();
  if (trimmed.length === 0) return true;

  const lower = trimmed.toLowerCase();
  const forbiddenProtocols = ['javascript:', 'data:', 'file:', 'intent:', 'ftp:'];
  if (forbiddenProtocols.some((proto) => lower.startsWith(proto))) {
    return false;
  }

  try {
    const parsed = new URL(trimmed);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

export class CreatePostDto {
  @IsString()
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @MinLength(1)
  @MaxLength(POST_CONTENT_MAX_LENGTH)
  @Matches(/\S/, { message: 'content must not be blank' })
  content!: string;

  @IsOptional()
  @IsEnum(PostCategory)
  category?: PostCategory;

  @IsOptional()
  @IsEnum(PostBackground)
  background?: PostBackground;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  mediaIds?: string[];

  @IsOptional()
  @IsString()
  linkUrl?: string;
}
