import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DatabaseService } from '../database/database.service';
import { MediaProcessingStatus, MediaProvider, PostMediaType } from '../generated/prisma/enums';
import { IMediaProvider, UploadMediaOptions } from './media-provider.interface';
import { KhabroCdnMediaProvider } from './providers/khabro-cdn-media.provider';
import { YouTubeMediaProvider } from './providers/youtube-media.provider';

export const ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
export const ALLOWED_VIDEO_MIMES = [
  'video/mp4',
  'video/webm',
  'video/quicktime',
  'video/x-matroska',
];

export const MAX_IMAGE_BYTES = 10 * 1024 * 1024; // 10MB
export const MAX_VIDEO_BYTES = 100 * 1024 * 1024; // 100MB

export const toPublicMediaResponse = (media: any) => ({
  id: media.id,
  type: media.type,
  provider: media.provider,
  url: media.mediaUrl,
  thumbnailUrl: media.thumbnailUrl ?? null,
  providerMediaId: media.providerMediaId ?? null,
  mimeType: media.mimeType ?? null,
  width: media.width ?? null,
  height: media.height ?? null,
  durationSeconds: media.durationSeconds ?? null,
  processingStatus: media.processingStatus,
  sortOrder: media.sortOrder ?? 0,
});

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly database: DatabaseService,
    private readonly youtubeProvider: YouTubeMediaProvider,
    private readonly cdnProvider: KhabroCdnMediaProvider,
  ) {}

  getActiveProvider(): IMediaProvider {
    const configured = this.configService.get<string>('POST_MEDIA_PROVIDER')?.toLowerCase();
    if (configured === 'khb_cdn') {
      return this.cdnProvider;
    }
    return this.youtubeProvider;
  }

  async uploadMedia(
    userId: string,
    fileBuffer: Buffer,
    filename: string,
    mimeType: string,
  ) {
    if (!fileBuffer || fileBuffer.length === 0) {
      throw new BadRequestException('Empty file uploaded');
    }

    const isImage = ALLOWED_IMAGE_MIMES.includes(mimeType.toLowerCase());
    const isVideo = ALLOWED_VIDEO_MIMES.includes(mimeType.toLowerCase());

    if (!isImage && !isVideo) {
      throw new BadRequestException(`Unsupported media type: ${mimeType}`);
    }

    if (isImage && fileBuffer.length > MAX_IMAGE_BYTES) {
      throw new BadRequestException('Image size exceeds maximum limit of 10MB');
    }

    if (isVideo && fileBuffer.length > MAX_VIDEO_BYTES) {
      throw new BadRequestException('Video size exceeds maximum limit of 100MB');
    }

    const provider = this.getActiveProvider();
    const type = isImage ? PostMediaType.IMAGE : PostMediaType.VIDEO;
    const uploadOptions: UploadMediaOptions = {
      fileBuffer,
      filename,
      mimeType,
      title: filename,
    };

    let result;
    try {
      if (isImage) {
        result = await provider.uploadImage(uploadOptions);
      } else {
        result = await provider.uploadVideo(uploadOptions);
      }
    } catch (error: any) {
      this.logger.error(`Media upload failed: ${error.message}`);
      throw new BadRequestException('Media upload failed');
    }

    const mediaRecord = await this.database.postMedia.create({
      data: {
        createdById: userId,
        type,
        provider: result.provider,
        mediaUrl: result.mediaUrl,
        thumbnailUrl: result.thumbnailUrl ?? null,
        providerMediaId: result.providerMediaId ?? null,
        mimeType: result.mimeType ?? mimeType,
        width: result.width ?? null,
        height: result.height ?? null,
        durationSeconds: result.durationSeconds ?? null,
        processingStatus: result.processingStatus ?? MediaProcessingStatus.READY,
      },
    });

    return toPublicMediaResponse(mediaRecord);
  }
}
