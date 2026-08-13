import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { PostReportReason } from '../../generated/prisma/enums';

export class CreateReportDto {
  @IsEnum(PostReportReason)
  reason: PostReportReason;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  description?: string;
}
