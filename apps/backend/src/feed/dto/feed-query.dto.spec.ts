import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { FeedQueryDto, FEED_DEFAULT_LIMIT, FEED_MAX_LIMIT } from './feed-query.dto';

describe('FeedQueryDto', () => {
  it('defaults the page size', () => {
    expect(plainToInstance(FeedQueryDto, {}).limit).toBe(FEED_DEFAULT_LIMIT);
  });

  it('accepts a valid limit and cursor', async () => {
    const errors = await validate(
      plainToInstance(FeedQueryDto, { limit: '30', cursor: 'eyJpZCI6IjEifQ==' }),
    );
    expect(errors).toHaveLength(0);
  });

  it('rejects limits outside the supported range', async () => {
    expect(
      (await validate(plainToInstance(FeedQueryDto, { limit: '0' }))).length,
    ).toBeGreaterThan(0);
    expect(
      (await validate(plainToInstance(FeedQueryDto, { limit: String(FEED_MAX_LIMIT + 1) }))).length,
    ).toBeGreaterThan(0);
  });

  it('rejects malformed cursors', async () => {
    expect(
      (await validate(plainToInstance(FeedQueryDto, { cursor: 'not base64' }))).length,
    ).toBeGreaterThan(0);
  });
});
