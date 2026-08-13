import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { DatabaseService } from '../database/database.service';

@Controller('health')
export class HealthController {
  private readonly redis: Redis;

  constructor(
    private readonly configService: ConfigService,
    private readonly database: DatabaseService,
  ) {
    this.redis = new Redis({
      host: this.configService.get<string>('REDIS_HOST', 'localhost'),
      port: this.configService.get<number>('REDIS_PORT', 6300),
      lazyConnect: true,
      maxRetriesPerRequest: 1,
    });
  }

  @Get()
  async check() {
    let dbOk = false;
    let redisOk = false;

    try {
      await this.database.$queryRaw`SELECT 1`;
      dbOk = true;
    } catch (_) {
      dbOk = false;
    }

    try {
      const pong = await this.redis.ping();
      redisOk = pong === 'PONG';
    } catch (_) {
      redisOk = false;
    }

    const isFullyOk = dbOk && redisOk;

    return {
      status: isFullyOk ? 'ok' : 'degraded',
      database: dbOk ? 'ok' : 'error',
      redis: redisOk ? 'ok' : 'error',
      timestamp: new Date().toISOString(),
    };
  }
}