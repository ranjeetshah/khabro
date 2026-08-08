import { Controller, Get } from '@nestjs/common';
import Redis from 'ioredis';
import { ConfigService } from '@nestjs/config';

@Controller('health')
export class HealthController {
  private readonly redis: Redis;

  constructor(private readonly configService: ConfigService) {
    this.redis = new Redis({
      host: this.configService.get<string>('REDIS_HOST', 'localhost'),
      port: this.configService.get<number>('REDIS_PORT', 6300),
    });
  }

  @Get()
  async check() {
    const redisStatus = await this.redis.ping();

    return {
      status: 'ok',
      database: 'ok',
      redis: redisStatus === 'PONG' ? 'ok' : 'error',
      timestamp: new Date().toISOString(),
    };
  }
}