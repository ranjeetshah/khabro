import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { KhabroCdnMediaProvider } from './providers/khabro-cdn-media.provider';
import { YouTubeMediaProvider } from './providers/youtube-media.provider';

@Module({
  imports: [DatabaseModule],
  controllers: [MediaController],
  providers: [MediaService, YouTubeMediaProvider, KhabroCdnMediaProvider],
  exports: [MediaService, YouTubeMediaProvider, KhabroCdnMediaProvider],
})
export class MediaModule {}
