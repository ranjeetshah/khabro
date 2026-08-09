import { DevelopmentLocalityResolver } from './development-locality.resolver';

describe('DevelopmentLocalityResolver', () => {
  const resolver = new DevelopmentLocalityResolver();

  it('resolves the first deterministic fixture', () => {
    expect(resolver.resolve(28.7041, 77.1025)).toEqual({
      id: 'development-locality-a',
      name: 'Test Locality A',
      city: 'Delhi',
      state: 'Delhi',
      country: 'India',
    });
  });

  it('resolves the second deterministic fixture', () => {
    expect(resolver.resolve(19.076, 72.8777)).toEqual({
      id: 'development-locality-b',
      name: 'Test Locality B',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
    });
  });

  it('returns null for unknown coordinates', () => {
    expect(resolver.resolve(0, 0)).toBeNull();
  });

  it('is deterministic', () => {
    expect(resolver.resolve(28.7041, 77.1025)).toEqual(
      resolver.resolve(28.7041, 77.1025),
    );
  });
});
