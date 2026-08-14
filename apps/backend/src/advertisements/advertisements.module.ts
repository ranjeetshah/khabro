import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { AdvertisementsController } from './advertisements.controller';
import { AdvertisementService } from './advertisements.service';
import { ModeratorAdvertisementsController } from './moderator-advertisements.controller';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [AdvertisementsController, ModeratorAdvertisementsController],
  providers: [AdvertisementService],
})
export class AdvertisementsModule {}
