import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/hospital.dart';

class HospitalFinderService {
  // TODO: Replace with your actual Google Places API key
  // Get it from: https://console.cloud.google.com/apis/credentials
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  
  static const String _placesApiUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  
  /// Get current location with proper error handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please grant location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable in app settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Fetch nearby hospitals within specified radius (default 10 km)
  /// Returns top 5 hospitals sorted by distance
  static Future<List<Hospital>> findNearbyHospitals({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int maxResults = 5,
  }) async {
    try {
      // Convert radius from km to meters (Google API uses meters)
      int radiusMeters = (radiusKm * 1000).toInt();

      // Build the API URL
      final url = Uri.parse(
        '$_placesApiUrl?location=$latitude,$longitude'
        '&radius=$radiusMeters'
        '&type=hospital'
        '&key=$_apiKey'
      );

      print('Fetching hospitals from: $url');

      // Make the API request
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          // Parse hospitals
          List<Hospital> hospitals = results
              .map((json) => Hospital.fromJson(json, latitude, longitude))
              .where((hospital) => hospital.distance <= radiusKm) // Filter within radius
              .toList();

          // Sort by distance (closest first)
          hospitals.sort((a, b) => a.distance.compareTo(b.distance));

          // Return top results
          return hospitals.take(maxResults).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw Exception('API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Invalid API key. Please check your Google Places API key.');
      } else {
        throw Exception('Failed to fetch hospitals. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby hospitals: $e');
      rethrow;
    }
  }

  /// Fetch hospitals at current location
  static Future<List<Hospital>> findHospitalsAtCurrentLocation({
    double radiusKm = 10.0,
    int maxResults = 5,
  }) async {
    final position = await getCurrentLocation();
    
    if (position == null) {
      throw Exception('Unable to get current location');
    }

    return await findNearbyHospitals(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: radiusKm,
      maxResults: maxResults,
    );
  }

  /// Open maps app with directions to hospital
  static Future<void> openDirections(Hospital hospital) async {
    // This will be implemented with url_launcher package
    // For now, this is a placeholder
    print('Opening directions to: ${hospital.name}');
  }

  /// Call hospital phone number
  static Future<void> callHospital(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('Phone number not available');
    }
    // This will be implemented with url_launcher package
    print('Calling: $phoneNumber');
  }

  /// Call ambulance (emergency number)
  static Future<void> callAmbulance({String country = 'IN'}) async {
    String emergencyNumber;
    switch (country.toUpperCase()) {
      case 'IN':
        emergencyNumber = '102'; // Ambulance in India
        break;
      case 'US':
        emergencyNumber = '911';
        break;
      case 'UK':
        emergencyNumber = '999';
        break;
      default:
        emergencyNumber = '112'; // International emergency
    }
    
    // This will be implemented with url_launcher package
    print('Calling ambulance: $emergencyNumber');
  }
}
