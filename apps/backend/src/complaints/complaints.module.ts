import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ComplaintsController } from './complaints.controller';
import { ComplaintService } from './complaints.service';

@Module({
  imports: [AuthModule],
  controllers: [ComplaintsController],
  providers: [ComplaintService],
  exports: [ComplaintService],
})
export class ComplaintsModule {}
