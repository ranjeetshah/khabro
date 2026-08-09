import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateLocationDto } from './update-location.dto';

async function validateDto(data: Record<string, unknown>) {
  return validate(plainToInstance(UpdateLocationDto, data));
}

const validLocation = {
  latitude: 28.7041,
  longitude: 77.1025,
  accuracyMeters: 25,
  capturedAt: '2026-08-09T08:00:00.000Z',
};

describe('UpdateLocationDto', () => {
  it('accepts valid coordinates and timestamp', async () => {
    await expect(validateDto(validLocation)).resolves.toHaveLength(0);
  });

  it('accepts location without optional accuracy', async () => {
    const { accuracyMeters: _, ...withoutAccuracy } = validLocation;
    await expect(validateDto(withoutAccuracy)).resolves.toHaveLength(0);
  });

  it.each([
    ['latitude below -90', { latitude: -90.001 }],
    ['latitude above 90', { latitude: 90.001 }],
    ['longitude below -180', { longitude: -180.001 }],
    ['longitude above 180', { longitude: 180.001 }],
    ['negative accuracy', { accuracyMeters: -1 }],
    ['invalid capturedAt', { capturedAt: 'not-a-date' }],
  ])('rejects %s', async (_, override) => {
    const errors = await validateDto({ ...validLocation, ...override });
    expect(errors.length).toBeGreaterThan(0);
  });

  it('rejects missing required fields', async () => {
    const errors = await validateDto({});
    expect(errors.map((error) => error.property)).toEqual(
      expect.arrayContaining(['latitude', 'longitude', 'capturedAt']),
    );
  });
});
