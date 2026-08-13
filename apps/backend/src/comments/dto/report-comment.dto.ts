import { Transform } from 'class-transformer';
import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { CommentReportReason } from '../../generated/prisma/client';

export class ReportCommentDto {
  @IsEnum(CommentReportReason)
  @IsNotEmpty()
  reason: CommentReportReason;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  description?: string;
}
