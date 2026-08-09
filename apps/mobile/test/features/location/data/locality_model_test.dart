import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/data/locality_model.dart';

const localityJson = {
  'id': 'development-locality-a',
  'name': 'Test Locality A',
  'city': 'Delhi',
  'state': 'Delhi',
  'country': 'India',
};

void main() {
  test('LocalityModel parses valid JSON', () {
    final locality = LocalityModel.fromJson(localityJson);

    expect(locality.name, 'Test Locality A');
    expect(locality.city, 'Delhi');
    expect(locality.state, 'Delhi');
    expect(locality.country, 'India');
  });

  test('LocalityModel serializes without coordinates', () {
    final locality = LocalityModel.fromJson(localityJson);

    expect(locality.toJson(), localityJson);
    expect(locality.toJson().containsKey('latitude'), isFalse);
    expect(locality.toJson().containsKey('longitude'), isFalse);
  });

  test('LocalityModel throws when required fields are missing', () {
    expect(
      () => LocalityModel.fromJson({'id': 'development-locality-a'}),
      throwsA(isA<TypeError>()),
    );
  });
}
