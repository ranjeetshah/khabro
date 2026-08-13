import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { CivicComplaintStatus } from '../../generated/prisma/enums';

export class UpdateComplaintStatusDto {
  @IsEnum(CivicComplaintStatus)
  status: CivicComplaintStatus;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}
