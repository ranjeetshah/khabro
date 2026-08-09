export type GeographicAreaType = 'COUNTRY' | 'STATE' | 'CITY' | 'LOCALITY';

export interface GeographicArea {
  id: string;
  name: string;
  type: GeographicAreaType;
  parent: GeographicArea | null;
}

export interface Locality extends GeographicArea {
  city: string;
  state: string;
  country: string;
}

export interface LocalityResolver {
  resolve(latitude: number, longitude: number): Locality | null;
}

export const LOCALITY_RESOLVER = Symbol('LOCALITY_RESOLVER');
