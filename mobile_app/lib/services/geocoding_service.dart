import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for a place and get coordinates
  static Future<Map<String, dynamic>?> searchPlace(String placeName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search?q=$placeName&format=json&limit=10&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ArogyaSetu Health App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          // Find the first result in India
          final indiaResult = results.firstWhere(
            (r) => (r['display_name']?.toLowerCase().contains('india') ?? false),
            orElse: () => null,
          );
          if (indiaResult != null) {
            return {
              'latitude': double.parse(indiaResult['lat']),
              'longitude': double.parse(indiaResult['lon']),
              'displayName': indiaResult['display_name'],
              'address': indiaResult['address'],
            };
          }
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding place: $e');
      return null;
    }
  }

  /// Reverse geocode - get place name from coordinates
  static Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?lat=$latitude&lon=$longitude&format=json',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ArogyaSetu Health App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }
}
