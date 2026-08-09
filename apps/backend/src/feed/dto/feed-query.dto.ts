import { Transform } from 'class-transformer';
import { IsBase64, IsInt, IsOptional, Max, Min } from 'class-validator';

export const FEED_DEFAULT_LIMIT = 20;
export const FEED_MAX_LIMIT = 50;

export class FeedQueryDto {
  @IsOptional()
  @Transform(({ value }) => (value === undefined ? value : Number(value)))
  @IsInt()
  @Min(1)
  @Max(FEED_MAX_LIMIT)
  limit: number = FEED_DEFAULT_LIMIT;

  @IsOptional()
  @IsBase64()
  cursor?: string;
}
