import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

const LOCALHOST_HOSTS = new Set(['localhost', '127.0.0.1', '::1', '0.0.0.0']);

/**
 * Validates that a URL is safe to open from the app.
 *
 * Only `https` is allowed in production use. `http` is permitted solely for
 * loopback hosts during development (localhost/127.0.0.1). All other schemes
 * (`javascript:`, `data:`, `file:`, `intent:`, `ftp:`, etc.) are rejected.
 */
export function isSafeUrl(value: unknown): boolean {
  if (typeof value !== 'string') {
    return false;
  }

  let parsed: URL;
  try {
    parsed = new URL(value.trim());
  } catch {
    return false;
  }

  if (parsed.protocol === 'https:') {
    return true;
  }

  if (parsed.protocol === 'http:') {
    return LOCALHOST_HOSTS.has(parsed.hostname.toLowerCase());
  }

  return false;
}

@ValidatorConstraint({ name: 'isSafeUrl', async: false })
export class IsSafeUrlConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    return isSafeUrl(value);
  }

  defaultMessage(): string {
    return '$property must be a valid https URL (http://localhost is allowed during development)';
  }
}

/**
 * Class-validator decorator that rejects unsafe ad URLs.
 */
export function IsSafeUrl(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsSafeUrlConstraint,
    });
  };
}
