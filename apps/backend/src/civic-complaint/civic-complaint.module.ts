import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { MailModule } from '../mail/mail.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { CivicComplaintController } from './civic-complaint.controller';
import { CivicComplaintService } from './civic-complaint.service';

@Module({
  imports: [
    DatabaseModule,
    MailModule,
    ConfigModule,
    AuthModule,
    NotificationsModule,
  ],
  controllers: [CivicComplaintController],
  providers: [CivicComplaintService],
  exports: [CivicComplaintService],
})
export class CivicComplaintModule {}
