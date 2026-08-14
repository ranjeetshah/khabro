import { MediaProcessingStatus, MediaProvider } from '../generated/prisma/enums';

export interface UploadMediaOptions {
  fileBuffer: Buffer;
  filename: string;
  mimeType: string;
  title?: string;
  description?: string;
}

export interface UploadResult {
  provider: MediaProvider;
  mediaUrl: string;
  thumbnailUrl?: string;
  providerMediaId?: string;
  mimeType?: string;
  width?: number;
  height?: number;
  durationSeconds?: number;
  processingStatus: MediaProcessingStatus;
}

export interface IMediaProvider {
  readonly name: MediaProvider;

  uploadImage(options: UploadMediaOptions): Promise<UploadResult>;
  uploadVideo(options: UploadMediaOptions): Promise<UploadResult>;
  deleteMedia(providerMediaId: string): Promise<boolean>;
  getPlaybackUrl(providerMediaId: string): string;
  getThumbnailUrl(providerMediaId: string): string | null;
}
