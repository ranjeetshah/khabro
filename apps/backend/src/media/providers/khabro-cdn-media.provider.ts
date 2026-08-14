import { Injectable } from '@nestjs/common';
import { MediaProcessingStatus, MediaProvider } from '../../generated/prisma/enums';
import { IMediaProvider, UploadMediaOptions, UploadResult } from '../media-provider.interface';

@Injectable()
export class KhabroCdnMediaProvider implements IMediaProvider {
  readonly name = MediaProvider.KHABRO_CDN;

  async uploadImage(options: UploadMediaOptions): Promise<UploadResult> {
    const mockId = `cdn_img_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const url = `https://cdn.khabro.org/images/${mockId}.${options.filename.split('.').pop() || 'jpg'}`;
    return {
      provider: MediaProvider.KHABRO_CDN,
      mediaUrl: url,
      thumbnailUrl: url,
      providerMediaId: mockId,
      mimeType: options.mimeType,
      processingStatus: MediaProcessingStatus.READY,
    };
  }

  async uploadVideo(options: UploadMediaOptions): Promise<UploadResult> {
    const mockId = `cdn_vid_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    return {
      provider: MediaProvider.KHABRO_CDN,
      mediaUrl: this.getPlaybackUrl(mockId),
      thumbnailUrl: this.getThumbnailUrl(mockId),
      providerMediaId: mockId,
      mimeType: options.mimeType,
      processingStatus: MediaProcessingStatus.READY,
    };
  }

  async deleteMedia(providerMediaId: string): Promise<boolean> {
    return true;
  }

  getPlaybackUrl(providerMediaId: string): string {
    return `https://cdn.khabro.org/videos/${providerMediaId}.mp4`;
  }

  getThumbnailUrl(providerMediaId: string): string {
    return `https://cdn.khabro.org/thumbnails/${providerMediaId}.jpg`;
  }
}
