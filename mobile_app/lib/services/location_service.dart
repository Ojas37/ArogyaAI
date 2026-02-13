import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  /// Get current location with timeout
  static Future<Position?> getCurrentLocationWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await getCurrentLocation().timeout(
        timeout,
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );
    } catch (e) {
      print('Error getting location with timeout: $e');
      rethrow;
    }
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
