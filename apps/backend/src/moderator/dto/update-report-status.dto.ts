import { IsEnum } from 'class-validator';
import { ReportStatus } from '../../generated/prisma/enums';

export class UpdateReportStatusDto {
  @IsEnum(ReportStatus)
  status: ReportStatus;
}
