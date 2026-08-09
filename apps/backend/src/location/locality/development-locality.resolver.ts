import { Locality, LocalityResolver } from './locality-resolver';

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
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
      };
    }

    return null;
  }
}
