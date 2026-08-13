import { IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { UserReportReason } from '../../generated/prisma/enums';

export class CreateUserReportDto {
  @IsEnum(UserReportReason)
  reason: UserReportReason;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(1000)
  description?: string;
}
