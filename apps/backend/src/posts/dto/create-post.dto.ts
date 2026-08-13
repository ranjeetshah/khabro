import { IsEnum, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { PostCategory } from '../../generated/prisma/enums';

export const POST_CONTENT_MAX_LENGTH = 5000;

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
}
