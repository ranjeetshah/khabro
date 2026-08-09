import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { CreatePostDto, POST_CONTENT_MAX_LENGTH } from './create-post.dto';

describe('CreatePostDto', () => {
  const errorsFor = (data: Record<string, unknown>) =>
    validate(plainToInstance(CreatePostDto, data));

  it('accepts trimmed text content', async () => {
    expect(await errorsFor({ content: ' Hello Khabro! ' })).toHaveLength(0);
  });

  it('rejects empty and whitespace-only content', async () => {
    expect((await errorsFor({ content: '' })).length).toBeGreaterThan(0);
    expect((await errorsFor({ content: '   ' })).length).toBeGreaterThan(0);
  });

  it('enforces the maximum content length', async () => {
    expect(
      (await errorsFor({ content: 'a'.repeat(POST_CONTENT_MAX_LENGTH) })).length,
    ).toBe(0);
    expect(
      (await errorsFor({ content: 'a'.repeat(POST_CONTENT_MAX_LENGTH + 1) }))
        .length,
    ).toBeGreaterThan(0);
  });

  it('rejects non-string content', async () => {
    expect((await errorsFor({ content: 123 })).length).toBeGreaterThan(0);
  });
});
