import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;
  let databaseService: any;

  beforeEach(async () => {
    databaseService = {
      $queryRaw: jest.fn().mockResolvedValue([{ 1: 1 }]),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        ConfigService,
        { provide: DatabaseService, useValue: databaseService },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('checks database and redis health safely', async () => {
    jest.spyOn((controller as any).redis, 'ping').mockResolvedValue('PONG');

    const result = await controller.check();

    expect(result.database).toBe('ok');
    expect(result.redis).toBe('ok');
    expect(result.status).toBe('ok');
  });

  it('handles redis connection failure gracefully', async () => {
    jest.spyOn((controller as any).redis, 'ping').mockRejectedValue(new Error('Connection error'));

    const result = await controller.check();

    expect(result.database).toBe('ok');
    expect(result.redis).toBe('error');
    expect(result.status).toBe('degraded');
  });
});
