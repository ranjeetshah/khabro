import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { MediaProcessingStatus, MediaProvider, PostMediaType } from '../generated/prisma/enums';
import { MediaService } from './media.service';
import { KhabroCdnMediaProvider } from './providers/khabro-cdn-media.provider';
import { YouTubeMediaProvider } from './providers/youtube-media.provider';

describe('MediaService & Provider Architecture', () => {
  let service: MediaService;
  let configService: ConfigService;

  const mockDatabase = {
    postMedia: {
      create: jest.fn().mockImplementation(({ data }) =>
        Promise.resolve({
          id: 'media-uuid-1',
          ...data,
        }),
      ),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        YouTubeMediaProvider,
        KhabroCdnMediaProvider,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === 'POST_MEDIA_PROVIDER') return 'youtube';
              if (key === 'YOUTUBE_API_KEY') return 'test-key';
              if (key === 'YOUTUBE_CLIENT_ID') return 'test-client-id';
              if (key === 'YOUTUBE_CLIENT_SECRET') return 'test-client-secret';
              if (key === 'YOUTUBE_REFRESH_TOKEN') return 'test-refresh-token';
              return null;
            }),
          },
        },
        { provide: DatabaseService, useValue: mockDatabase },
      ],
    }).compile();

    service = module.get(MediaService);
    configService = module.get(ConfigService);
  });

  it('selects YouTubeMediaProvider when POST_MEDIA_PROVIDER is youtube', () => {
    const provider = service.getActiveProvider();
    expect(provider.name).toBe(MediaProvider.YOUTUBE);
  });

  it('switches to KhabroCdnMediaProvider when POST_MEDIA_PROVIDER is khb_cdn without schema redesign', () => {
    jest.spyOn(configService, 'get').mockImplementation((key: string) => {
      if (key === 'POST_MEDIA_PROVIDER') return 'khb_cdn';
      return null;
    });

    const provider = service.getActiveProvider();
    expect(provider.name).toBe(MediaProvider.KHABRO_CDN);
  });

  it('rejects unsupported media MIME types', async () => {
    await expect(
      service.uploadMedia(
        'user-1',
        Buffer.from('test'),
        'file.exe',
        'application/x-msdownload',
      ),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects images exceeding 10MB size limit', async () => {
    const oversizedBuffer = Buffer.alloc(11 * 1024 * 1024);
    await expect(
      service.uploadMedia('user-1', oversizedBuffer, 'large.jpg', 'image/jpeg'),
    ).rejects.toThrow(BadRequestException);
  });

  it('uploads valid image asset and returns generic media contract without secrets', async () => {
    const validImage = Buffer.from('test-image-data');
    const result = await service.uploadMedia(
      'user-1',
      validImage,
      'photo.jpg',
      'image/jpeg',
    );

    expect(result).toEqual({
      id: 'media-uuid-1',
      type: PostMediaType.IMAGE,
      provider: MediaProvider.YOUTUBE,
      url: expect.any(String),
      thumbnailUrl: expect.any(String),
      providerMediaId: null,
      mimeType: 'image/jpeg',
      width: null,
      height: null,
      durationSeconds: null,
      processingStatus: MediaProcessingStatus.READY,
      sortOrder: 0,
    });
    expect(result).not.toHaveProperty('createdById');
    expect(result).not.toHaveProperty('YOUTUBE_API_KEY');
    expect(result).not.toHaveProperty('YOUTUBE_REFRESH_TOKEN');
  });

  it('uploads video asset and returns playbackUrl & YouTube providerMediaId', async () => {
    const validVideo = Buffer.from('test-video-data');
    const result = await service.uploadMedia(
      'user-1',
      validVideo,
      'clip.mp4',
      'video/mp4',
    );

    expect(result).toEqual({
      id: 'media-uuid-1',
      type: PostMediaType.VIDEO,
      provider: MediaProvider.YOUTUBE,
      url: expect.stringContaining('youtube.com/embed/'),
      thumbnailUrl: expect.stringContaining('img.youtube.com/vi/'),
      providerMediaId: expect.any(String),
      mimeType: 'video/mp4',
      width: null,
      height: null,
      durationSeconds: null,
      processingStatus: MediaProcessingStatus.READY,
      sortOrder: 0,
    });
  });
});
