import 'dart:math' show sin, cos, sqrt, asin, pi;

class Hospital {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in kilometers
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final bool openNow;

  Hospital({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.openNow = false,
  });

  factory Hospital.fromJson(Map<String, dynamic> json, double userLat, double userLng) {
    final lat = json['geometry']['location']['lat'];
    final lng = json['geometry']['location']['lng'];
    final distance = _calculateDistance(userLat, userLng, lat, lng);

    return Hospital(
      name: json['name'] ?? 'Unknown Hospital',
      address: json['vicinity'] ?? json['formatted_address'] ?? 'No address available',
      latitude: lat,
      longitude: lng,
      distance: distance,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      phoneNumber: json['formatted_phone_number'],
      openNow: json['opening_hours']?['open_now'] ?? false,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of Earth in kilometers
    final double dLat = _degreeToRadian(lat2 - lat1);
    final double dLon = _degreeToRadian(lon2 - lon1);

    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) * cos(_degreeToRadian(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _degreeToRadian(double degree) {
    return degree * (pi / 180);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'phoneNumber': phoneNumber,
      'openNow': openNow,
    };
  }
}
