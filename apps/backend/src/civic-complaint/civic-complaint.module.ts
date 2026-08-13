import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '../database/database.module';
import { MailModule } from '../mail/mail.module';
import { CivicComplaintService } from './civic-complaint.service';

@Module({
  imports: [DatabaseModule, MailModule, ConfigModule],
  providers: [CivicComplaintService],
  exports: [CivicComplaintService],
})
export class CivicComplaintModule {}
