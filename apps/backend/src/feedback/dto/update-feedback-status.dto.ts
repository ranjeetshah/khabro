import { IsEnum } from 'class-validator';
import { FeedbackStatus } from '../../generated/prisma/enums';

export class UpdateFeedbackStatusDto {
  @IsEnum(FeedbackStatus)
  status!: FeedbackStatus;
}
