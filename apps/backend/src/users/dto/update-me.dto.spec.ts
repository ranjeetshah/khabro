import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { UpdateMeDto } from './update-me.dto';

describe('UpdateMeDto', () => {
  async function validateDto(data: Record<string, any>) {
    const dto = plainToInstance(UpdateMeDto, data);
    return validate(dto);
  }

  it('should pass with valid name', async () => {
    const errors = await validateDto({ name: 'Valid Name' });
    expect(errors).toHaveLength(0);
  });

  it('should pass with no fields (empty update)', async () => {
    const errors = await validateDto({});
    expect(errors).toHaveLength(0);
  });

  it('should fail with empty string name', async () => {
    const errors = await validateDto({ name: '' });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('should fail with name exceeding 100 characters', async () => {
    const errors = await validateDto({ name: 'a'.repeat(101) });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('should pass with name exactly 100 characters', async () => {
    const errors = await validateDto({ name: 'a'.repeat(100) });
    expect(errors).toHaveLength(0);
  });

  it('should fail with non-string name', async () => {
    const errors = await validateDto({ name: 12345 });
    expect(errors.length).toBeGreaterThan(0);
  });
});
