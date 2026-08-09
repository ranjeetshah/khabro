export interface Locality {
  id: string;
  name: string;
  city: string;
  state: string;
  country: string;
}

export interface LocalityResolver {
  resolve(latitude: number, longitude: number): Locality | null;
}

export const LOCALITY_RESOLVER = Symbol('LOCALITY_RESOLVER');
