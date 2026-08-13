import { IsEnum, IsOptional, IsString, MaxLength, MinLength, Matches } from 'class-validator';
import { Transform } from 'class-transformer';
import { FeedbackType } from '../../generated/prisma/enums';

export const FEEDBACK_MESSAGE_MAX_LENGTH = 2000;

export class CreateFeedbackDto {
  @IsEnum(FeedbackType)
  type!: FeedbackType;

  @IsString()
  @MinLength(1)
  @MaxLength(FEEDBACK_MESSAGE_MAX_LENGTH)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Matches(/\S/, { message: 'message must not be blank' })
  message!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  appVersion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  platform?: string;
}
