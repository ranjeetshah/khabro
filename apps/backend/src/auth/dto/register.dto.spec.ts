import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { RegisterDto } from './register.dto';
import { DevLoginDto } from './dev-login.dto';

async function validateDto<T extends object>(DtoClass: new () => T, data: Record<string, any>) {
  const dto = plainToInstance(DtoClass, data);
  return validate(dto);
}

describe('RegisterDto', () => {
  it('should pass with valid phone with + prefix', async () => {
    const errors = await validateDto(RegisterDto, { phone: '+919876543210' });
    expect(errors).toHaveLength(0);
  });

  it('should pass with valid phone without + prefix', async () => {
    const errors = await validateDto(RegisterDto, { phone: '919876543210' });
    expect(errors).toHaveLength(0);
  });

  it('should fail with empty string phone', async () => {
    const errors = await validateDto(RegisterDto, { phone: '' });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should fail with phone starting with 0', async () => {
    const errors = await validateDto(RegisterDto, { phone: '09876543210' });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should fail with phone too short (less than 7 digits)', async () => {
    const errors = await validateDto(RegisterDto, { phone: '+12345' });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should fail with phone containing letters', async () => {
    const errors = await validateDto(RegisterDto, { phone: '+9198765abcde' });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should fail when phone field is missing', async () => {
    const errors = await validateDto(RegisterDto, {});
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should pass when optional name is omitted', async () => {
    const errors = await validateDto(RegisterDto, { phone: '+919876543210' });
    expect(errors).toHaveLength(0);
  });

  it('should pass with a valid name', async () => {
    const errors = await validateDto(RegisterDto, { phone: '+919876543210', name: 'John Doe' });
    expect(errors).toHaveLength(0);
  });

  it('should fail when name exceeds 100 characters', async () => {
    const longName = 'a'.repeat(101);
    const errors = await validateDto(RegisterDto, { phone: '+919876543210', name: longName });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('name');
  });
});

describe('DevLoginDto', () => {
  it('should pass with valid phone', async () => {
    const errors = await validateDto(DevLoginDto, { phone: '+919876543210' });
    expect(errors).toHaveLength(0);
  });

  it('should fail with empty string phone', async () => {
    const errors = await validateDto(DevLoginDto, { phone: '' });
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });

  it('should fail when phone field is missing', async () => {
    const errors = await validateDto(DevLoginDto, {});
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('phone');
  });
});
