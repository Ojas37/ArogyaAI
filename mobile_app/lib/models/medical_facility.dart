import 'dart:math' as math;

class MedicalFacility {
  final String name;
  final double latitude;
  final double longitude;
  final String type; // hospital, clinic, pharmacy
  final double? distanceInKm;
  final String? address;
  final String? phone;

  MedicalFacility({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.distanceInKm,
    this.address,
    this.phone,
  });

  /// Generate Google Maps redirect link (for search only)
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Generate Google Maps directions link from user's location
  String getDirectionsUrl({
    required double originLat,
    required double originLng,
    String travelMode = 'driving', // driving, walking, bicycling, transit
  }) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$latitude,$longitude&travelmode=$travelMode';
  }

  /// Calculate distance from user's location
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  MedicalFacility copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? type,
    double? distanceInKm,
    String? address,
    String? phone,
  }) {
    return MedicalFacility(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'distanceInKm': distanceInKm,
      'address': address,
      'phone': phone,
    };
  }

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    return MedicalFacility(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      type: json['type'],
      distanceInKm: json['distanceInKm'],
      address: json['address'],
      phone: json['phone'],
    );
  }

  @override
  String toString() {
    return 'MedicalFacility(name: $name, type: $type, distance: ${distanceInKm?.toStringAsFixed(2)} km)';
  }
}
