import { isSafeUrl } from './safe-url';

describe('isSafeUrl', () => {
  it('accepts https URLs', () => {
    expect(isSafeUrl('https://example.com/path?q=1')).toBe(true);
    expect(isSafeUrl('https://cdn.example.com/image.jpg')).toBe(true);
  });

  it('accepts http on loopback hosts for development', () => {
    expect(isSafeUrl('http://localhost:3000/creative.jpg')).toBe(true);
    expect(isSafeUrl('http://127.0.0.1/image.png')).toBe(true);
  });

  it('rejects javascript scheme', () => {
    expect(isSafeUrl('javascript:alert(1)')).toBe(false);
  });

  it('rejects data scheme', () => {
    expect(isSafeUrl('data:text/html;base64,PHNjcmlwdD4=')).toBe(false);
  });

  it('rejects file scheme', () => {
    expect(isSafeUrl('file:///etc/passwd')).toBe(false);
  });

  it('rejects intent scheme', () => {
    expect(isSafeUrl('intent://example.com')).toBe(false);
  });

  it('rejects ftp scheme', () => {
    expect(isSafeUrl('ftp://example.com/file')).toBe(false);
  });

  it('rejects http on non-loopback hosts', () => {
    expect(isSafeUrl('http://example.com/creative.jpg')).toBe(false);
  });

  it('rejects malformed URLs', () => {
    expect(isSafeUrl('not a url')).toBe(false);
    expect(isSafeUrl('')).toBe(false);
  });

  it('rejects non-string values', () => {
    expect(isSafeUrl(null)).toBe(false);
    expect(isSafeUrl(123)).toBe(false);
  });

  it('trims surrounding whitespace before validating', () => {
    expect(isSafeUrl('  https://example.com/a  ')).toBe(true);
  });
});
