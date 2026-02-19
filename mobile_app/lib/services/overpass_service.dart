import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_facility.dart';

class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  static const double _radiusMeters = 10000; // 10 km

  /// Search for nearby medical facilities based on type
  static Future<List<MedicalFacility>> searchNearbyFacilities({
    required double latitude,
    required double longitude,
    required String facilityType, // hospital, clinic, pharmacy
    int limit = 5,
    double radiusMeters = 10000,
  }) async {
    try {
      final query = _buildOverpassQuery(
        latitude: latitude,
        longitude: longitude,
        facilityType: facilityType,
        radiusMeters: radiusMeters,
      );
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {'data': query},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse and filter facilities
        final facilities = _parseOverpassResponse(
          data,
          userLat: latitude,
          userLon: longitude,
        );
        // Sort by distance
        facilities.sort((a, b) {
          if (a.distanceInKm == null) return 1;
          if (b.distanceInKm == null) return -1;
          return a.distanceInKm!.compareTo(b.distanceInKm!);
        });
        // Return top results
        return facilities.take(limit).toList();
      } else {
        throw Exception('Failed to fetch facilities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching facilities: $e');
      rethrow;
    }
  }

  /// Build Overpass QL query
  static String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    required String facilityType,
    required double radiusMeters,
  }) {
    // Parse facility types
    final types = facilityType.split(',').map((t) => t.trim()).toList();

    // Build query parts for each type
    final queryParts = <String>[];

    for (final type in types) {
      String amenity;
      switch (type.toLowerCase()) {
        case 'hospital':
          amenity = 'hospital';
          break;
        case 'clinic':
          amenity = 'clinic';
          break;
        case 'pharmacy':
          amenity = 'pharmacy';
          break;
        default:
          amenity = 'hospital';
      }

      // Add node and way queries for this amenity type
      queryParts.add(
          'node["amenity"="$amenity"](around:$radiusMeters,$latitude,$longitude);');
      queryParts.add(
          'way["amenity"="$amenity"](around:$radiusMeters,$latitude,$longitude);');
    }

    // Combine all parts
    final query = '''
[out:json][timeout:15];
(
  ${queryParts.join('\n  ')}
);
out center;
''';

    return query;
  }

  /// Parse Overpass API response
  static List<MedicalFacility> _parseOverpassResponse(
    Map<String, dynamic> data, {
    required double userLat,
    required double userLon,
  }) {
    final facilities = <MedicalFacility>[];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        try {
          // Get coordinates
          double? lat;
          double? lon;

          if (element['type'] == 'node') {
            lat = element['lat']?.toDouble();
            lon = element['lon']?.toDouble();
          } else if (element['type'] == 'way' && element['center'] != null) {
            lat = element['center']['lat']?.toDouble();
            lon = element['center']['lon']?.toDouble();
          }

          if (lat == null || lon == null) continue;

          // Get tags
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags == null) continue;

          // Get name (with fallback)
          final name = tags['name'] ??
              tags['operator'] ??
              tags['brand'] ??
              'Unnamed ${tags['amenity'] ?? 'Facility'}';

          // Get type
          final type = tags['amenity'] ?? 'unknown';

          // Get address
          final address = _buildAddress(tags);

          // Get phone
          final phone = tags['phone'] ?? tags['contact:phone'];

          // Calculate distance
          final distance = MedicalFacility.calculateDistance(
            userLat,
            userLon,
            lat,
            lon,
          );

          facilities.add(MedicalFacility(
            name: name,
            latitude: lat,
            longitude: lon,
            type: type,
            distanceInKm: distance,
            address: address,
            phone: phone,
          ));
        } catch (e) {
          print('Error parsing facility element: $e');
          continue;
        }
      }
    }

    return facilities;
  }

  /// Build address from tags
  static String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:housenumber'] != null || tags['addr:street'] != null) {
      final number = tags['addr:housenumber'] ?? '';
      final street = tags['addr:street'] ?? '';
      if (number.isNotEmpty || street.isNotEmpty) {
        parts.add('$number $street'.trim());
      }
    }

    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    }

    if (tags['addr:postcode'] != null) {
      parts.add(tags['addr:postcode']);
    }

    return parts.isEmpty ? null : parts.join(', ');
  }
}
