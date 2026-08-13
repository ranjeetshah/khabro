import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { ModeratorController } from './moderator.controller';
import { ModeratorService } from './moderator.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [ModeratorController],
  providers: [ModeratorService],
})
export class ModeratorModule {}
