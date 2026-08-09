import { DevelopmentLocalityResolver } from './development-locality.resolver';

describe('DevelopmentLocalityResolver', () => {
  const resolver = new DevelopmentLocalityResolver();

  it('resolves the first deterministic fixture', () => {
    expect(resolver.resolve(28.7041, 77.1025)).toEqual({
      id: 'development-locality-a',
      name: 'Test Locality A',
      type: 'LOCALITY',
      parent: {
        id: 'development-city-delhi',
        name: 'Delhi',
        type: 'CITY',
        parent: {
          id: 'development-state-delhi',
          name: 'Delhi',
          type: 'STATE',
          parent: {
            id: 'development-country-india',
            name: 'India',
            type: 'COUNTRY',
            parent: null,
          },
        },
      },
      city: 'Delhi',
      state: 'Delhi',
      country: 'India',
    });
  });

  it('resolves the second deterministic fixture', () => {
    expect(resolver.resolve(19.076, 72.8777)).toEqual({
      id: 'development-locality-b',
      name: 'Test Locality B',
      type: 'LOCALITY',
      parent: {
        id: 'development-city-mumbai',
        name: 'Mumbai',
        type: 'CITY',
        parent: {
          id: 'development-state-maharashtra',
          name: 'Maharashtra',
          type: 'STATE',
          parent: {
            id: 'development-country-india',
            name: 'India',
            type: 'COUNTRY',
            parent: null,
          },
        },
      },
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

  it('uses valid country -> state -> city -> locality parent relationships', () => {
    const locality = resolver.resolve(28.7041, 77.1025)!;

    expect(locality.type).toBe('LOCALITY');
    expect(locality.parent?.type).toBe('CITY');
    expect(locality.parent?.parent?.type).toBe('STATE');
    expect(locality.parent?.parent?.parent?.type).toBe('COUNTRY');
    expect(locality.parent?.parent?.parent?.parent).toBeNull();
  });
});
