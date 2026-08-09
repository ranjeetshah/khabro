import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DatabaseService } from '../database/database.service';
import { WitnessService } from './witness.service';

describe('WitnessService', () => {
  let service: WitnessService;

  const database = {
    post: {
      findFirst: jest.fn(),
    },
    witness: {
      upsert: jest.fn(),
      deleteMany: jest.fn(),
      count: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WitnessService,
        {
          provide: DatabaseService,
          useValue: database,
        },
      ],
    }).compile();

    service = module.get(WitnessService);

    database.post.findFirst.mockResolvedValue({
      id: 'post-1',
    });

    database.witness.count.mockResolvedValue(1);

    database.witness.findFirst.mockResolvedValue({
      id: 'witness-1',
    });
  });

  it('is defined', () => {
    expect(service).toBeDefined();
  });

  it('witnesses a post and returns metadata', async () => {
    await expect(
      service.witness('user-1', 'post-1'),
    ).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: true,
    });

    expect(database.witness.upsert).toHaveBeenCalledWith({
      where: {
        userId_postId: {
          userId: 'user-1',
          postId: 'post-1',
        },
      },
      create: {
        userId: 'user-1',
        postId: 'post-1',
      },
      update: {},
    });
  });

  it('uses an idempotent upsert for duplicate witnesses', async () => {
    await service.witness('user-1', 'post-1');
    await service.witness('user-1', 'post-1');

    expect(database.witness.upsert).toHaveBeenCalledTimes(2);
  });

  it('unwitnesses safely, including an already-unwitnessed post', async () => {
    database.witness.count.mockResolvedValue(0);
    database.witness.findFirst.mockResolvedValue(null);

    await expect(
      service.unwitness('user-1', 'post-1'),
    ).resolves.toEqual({
      witnessCount: 0,
      witnessedByMe: false,
    });

    expect(database.witness.deleteMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        postId: 'post-1',
      },
    });
  });

  it('rejects witnessing a missing or deleted post', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(
      service.witness('user-1', 'missing'),
    ).rejects.toThrow(NotFoundException);

    await expect(
      service.unwitness('user-1', 'missing'),
    ).rejects.toThrow(NotFoundException);

    expect(database.witness.upsert).not.toHaveBeenCalled();
    expect(database.witness.deleteMany).not.toHaveBeenCalled();
  });

  it('returns count and current-user state without exposing witness rows', async () => {
    database.witness.count.mockResolvedValue(2);
    database.witness.findFirst.mockResolvedValue(null);

    await expect(
      service.getStatus('user-2', 'post-1'),
    ).resolves.toEqual({
      witnessCount: 2,
      witnessedByMe: false,
    });
  });

  it('checks only active posts before returning witness status', async () => {
    await service.getStatus('user-1', 'post-1');

    expect(database.post.findFirst).toHaveBeenCalledWith({
      where: {
        id: 'post-1',
        deletedAt: null,
      },
      select: {
        id: true,
      },
    });
  });

  it('rejects witnessing a soft-deleted post', async () => {
    database.post.findFirst.mockResolvedValue(null);

    await expect(
      service.witness('user-1', 'deleted-post'),
    ).rejects.toThrow(NotFoundException);

    await expect(
      service.unwitness('user-1', 'deleted-post'),
    ).rejects.toThrow(NotFoundException);

    await expect(
      service.getStatus('user-1', 'deleted-post'),
    ).rejects.toThrow(NotFoundException);

    expect(database.witness.upsert).not.toHaveBeenCalled();
    expect(database.witness.deleteMany).not.toHaveBeenCalled();
  });

  it('keeps witness state isolated per user', async () => {
    database.witness.count.mockResolvedValue(1);
    database.witness.findFirst.mockResolvedValue({ id: 'witness-1' });

    await expect(
      service.getStatus('user-1', 'post-1'),
    ).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: true,
    });

    database.witness.findFirst.mockResolvedValue(null);

    await expect(
      service.getStatus('user-2', 'post-1'),
    ).resolves.toEqual({
      witnessCount: 1,
      witnessedByMe: false,
    });
  });
});