import {
  BadRequestException,
  Controller,
  Get,
  Post,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MediaService } from './media.service';

type AuthenticatedRequest = Request & {
  user: {
    sub: string;
  };
};

@Controller()
export class MediaController {
  constructor(
    private readonly mediaService: MediaService,
    private readonly configService: ConfigService,
  ) {}

  @Post('posts/media/upload')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadMedia(
    @Req() request: Request,
    @UploadedFile() file: any,
  ) {
    if (!file || !file.buffer) {
      throw new BadRequestException('No file uploaded');
    }

    const userId = (request as AuthenticatedRequest).user.sub;
    return this.mediaService.uploadMedia(
      userId,
      file.buffer,
      file.originalname || 'upload',
      file.mimetype || 'application/octet-stream',
    );
  }

  @Get('internal/youtube/auth')
  getYouTubeAuthUrl() {
    const clientId = this.configService.get<string>('YOUTUBE_CLIENT_ID');
    if (!clientId) {
      throw new BadRequestException('YouTube client ID not configured');
    }

    const redirectUri =
      this.configService.get<string>('YOUTUBE_REDIRECT_URI') ||
      'http://localhost:3000/internal/youtube/callback';

    const scope = 'https://www.googleapis.com/auth/youtube.upload';
    const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${encodeURIComponent(
      clientId,
    )}&redirect_uri=${encodeURIComponent(
      redirectUri,
    )}&response_type=code&scope=${encodeURIComponent(
      scope,
    )}&access_type=offline&prompt=consent`;

    return { authUrl };
  }

  @Get('internal/youtube/callback')
  async handleYouTubeCallback(@Query('code') code: string) {
    if (!code) {
      throw new BadRequestException('Authorization code missing');
    }

    const clientId = this.configService.get<string>('YOUTUBE_CLIENT_ID');
    const clientSecret = this.configService.get<string>('YOUTUBE_CLIENT_SECRET');
    const redirectUri =
      this.configService.get<string>('YOUTUBE_REDIRECT_URI') ||
      'http://localhost:3000/internal/youtube/callback';

    if (!clientId || !clientSecret) {
      throw new BadRequestException('YouTube OAuth client credentials missing');
    }

    try {
      const response = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          code,
          client_id: clientId,
          client_secret: clientSecret,
          redirect_uri: redirectUri,
          grant_type: 'authorization_code',
        }).toString(),
      });

      if (!response.ok) {
        throw new BadRequestException('Failed to exchange authorization code');
      }

      const data = (await response.json()) as { refresh_token?: string };

      if (!data.refresh_token) {
        return {
          status: 'SUCCESS',
          message:
            'Authorization code exchanged successfully, but no refresh_token was returned. (User may have already granted access; re-authorize with prompt=consent if refresh_token is required).',
        };
      }

      // Secure setup confirmation — never returns credentials to client or log
      return {
        status: 'SUCCESS',
        message:
          'YouTube OAuth authorization completed successfully. Configure YOUTUBE_REFRESH_TOKEN in backend environment.',
      };
    } catch (error: any) {
      throw new BadRequestException('YouTube OAuth exchange failed');
    }
  }
}
