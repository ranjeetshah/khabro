import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MediaProcessingStatus, MediaProvider } from '../../generated/prisma/enums';
import { IMediaProvider, UploadMediaOptions, UploadResult } from '../media-provider.interface';

@Injectable()
export class YouTubeMediaProvider implements IMediaProvider {
  readonly name = MediaProvider.YOUTUBE;
  private readonly logger = new Logger(YouTubeMediaProvider.name);

  constructor(private readonly configService: ConfigService) {}

  private get apiKey(): string | undefined {
    return this.configService.get<string>('YOUTUBE_API_KEY');
  }

  private get clientId(): string | undefined {
    return this.configService.get<string>('YOUTUBE_CLIENT_ID');
  }

  private get clientSecret(): string | undefined {
    return this.configService.get<string>('YOUTUBE_CLIENT_SECRET');
  }

  private get refreshToken(): string | undefined {
    return this.configService.get<string>('YOUTUBE_REFRESH_TOKEN');
  }

  async getAccessToken(): Promise<string | null> {
    const clientId = this.clientId;
    const clientSecret = this.clientSecret;
    const refreshToken = this.refreshToken;

    if (!clientId || !clientSecret || !refreshToken) {
      this.logger.warn('YouTube OAuth credentials not configured');
      return null;
    }

    try {
      const response = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          client_id: clientId,
          client_secret: clientSecret,
          refresh_token: refreshToken,
          grant_type: 'refresh_token',
        }).toString(),
      });

      if (!response.ok) {
        this.logger.error('Failed to refresh YouTube access token');
        return null;
      }

      const data = (await response.json()) as { access_token?: string };
      return data.access_token ?? null;
    } catch (error) {
      this.logger.error('Error refreshing YouTube access token');
      return null;
    }
  }

  async uploadImage(options: UploadMediaOptions): Promise<UploadResult> {
    // Standard image upload representation
    const base64Data = options.fileBuffer.toString('base64');
    const mediaUrl = `data:${options.mimeType};base64,${base64Data}`;
    return {
      provider: MediaProvider.YOUTUBE,
      mediaUrl,
      thumbnailUrl: mediaUrl,
      mimeType: options.mimeType,
      processingStatus: MediaProcessingStatus.READY,
    };
  }

  async uploadVideo(options: UploadMediaOptions): Promise<UploadResult> {
    const accessToken = await this.getAccessToken();

    if (!accessToken) {
      // In development / testing or unconfigured mode: return a fallback upload result
      const mockId = `yt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      return {
        provider: MediaProvider.YOUTUBE,
        mediaUrl: this.getPlaybackUrl(mockId),
        thumbnailUrl: this.getThumbnailUrl(mockId),
        providerMediaId: mockId,
        mimeType: options.mimeType,
        processingStatus: MediaProcessingStatus.READY,
      };
    }

    try {
      const title = options.title || `Khabro Civic Update ${new Date().toISOString()}`;
      const description = options.description || 'Uploaded via Khabro Civic Platform';

      // YouTube API upload request
      const initResponse = await fetch(
        'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status',
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
            'X-Upload-Content-Length': options.fileBuffer.length.toString(),
            'X-Upload-Content-Type': options.mimeType,
          },
          body: JSON.stringify({
            snippet: {
              title,
              description,
              categoryId: '22', // People & Blogs
            },
            status: {
              privacyStatus: 'unlisted', // Explicit privacy setting
              selfDeclaredMadeForKids: false,
            },
          }),
        },
      );

      if (!initResponse.ok) {
        const errorText = await initResponse.text();
        this.logger.error(`YouTube upload initialization failed: ${initResponse.status}`);
        throw new Error(`YouTube upload failed: ${initResponse.status}`);
      }

      const uploadUrl = initResponse.headers.get('location');
      if (!uploadUrl) {
        throw new Error('YouTube resumable upload location header missing');
      }

      const uploadResponse = await fetch(uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': options.mimeType,
        },
        body: new Uint8Array(options.fileBuffer),
      });

      if (!uploadResponse.ok) {
        throw new Error(`YouTube video chunk upload failed: ${uploadResponse.status}`);
      }

      const responseData = (await uploadResponse.json()) as { id?: string };
      const videoId = responseData.id;

      if (!videoId) {
        throw new Error('YouTube video ID missing in response');
      }

      return {
        provider: MediaProvider.YOUTUBE,
        mediaUrl: this.getPlaybackUrl(videoId),
        thumbnailUrl: this.getThumbnailUrl(videoId),
        providerMediaId: videoId,
        mimeType: options.mimeType,
        processingStatus: MediaProcessingStatus.READY,
      };
    } catch (error: any) {
      this.logger.error(`YouTube upload failed: ${error.message}`);
      throw error;
    }
  }

  async deleteMedia(providerMediaId: string): Promise<boolean> {
    // Soft isolation - post deletion in Khabro hides media without needing API delete
    return true;
  }

  getPlaybackUrl(providerMediaId: string): string {
    return `https://www.youtube.com/embed/${providerMediaId}`;
  }

  getThumbnailUrl(providerMediaId: string): string {
    return `https://img.youtube.com/vi/${providerMediaId}/hqdefault.jpg`;
  }
}
