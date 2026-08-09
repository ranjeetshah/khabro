import type { GeographicArea, Locality, LocalityResolver } from './locality-resolver';

const INDIA: GeographicArea = {
  id: 'development-country-india',
  name: 'India',
  type: 'COUNTRY',
  parent: null,
};

const DELHI_STATE: GeographicArea = {
  id: 'development-state-delhi',
  name: 'Delhi',
  type: 'STATE',
  parent: INDIA,
};

const DELHI_CITY: GeographicArea = {
  id: 'development-city-delhi',
  name: 'Delhi',
  type: 'CITY',
  parent: DELHI_STATE,
};

const MAHARASHTRA: GeographicArea = {
  id: 'development-state-maharashtra',
  name: 'Maharashtra',
  type: 'STATE',
  parent: INDIA,
};

const MUMBAI: GeographicArea = {
  id: 'development-city-mumbai',
  name: 'Mumbai',
  type: 'CITY',
  parent: MAHARASHTRA,
};

/**
 * Development-only deterministic fixture resolver.
 * Replace with a production locality/geocoding provider before production use.
 */
export class DevelopmentLocalityResolver implements LocalityResolver {
  resolve(latitude: number, longitude: number): Locality | null {
    if (
      latitude >= 28.7 &&
      latitude <= 28.8 &&
      longitude >= 77.0 &&
      longitude <= 77.2
    ) {
      return {
        id: 'development-locality-a',
        name: 'Test Locality A',
        type: 'LOCALITY',
        parent: DELHI_CITY,
        city: 'Delhi',
        state: 'Delhi',
        country: 'India',
      };
    }

    if (
      latitude >= 19.0 &&
      latitude <= 19.2 &&
      longitude >= 72.8 &&
      longitude <= 73.0
    ) {
      return {
        id: 'development-locality-b',
        name: 'Test Locality B',
        type: 'LOCALITY',
        parent: MUMBAI,
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
      };
    }

    return null;
  }
}
