/// A human-readable locality resolved from the authenticated user's location.
class LocalityModel {
  const LocalityModel({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.country,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String country;

  factory LocalityModel.fromJson(Map<String, dynamic> json) {
    return LocalityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
    };
  }
}
