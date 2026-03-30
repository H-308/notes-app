import 'package:geolocator/geolocator.dart';
import 'package:notes_app/core/constants/app_constants.dart';

/// Service for handling location-based operations
class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Get current user location
  /// Returns a tuple of (latitude, longitude)
  /// Throws exception if location services are disabled or permission denied
  Future<(double, double)> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final status = await Geolocator.requestPermission();
        if (status == LocationPermission.denied) {
          throw Exception(AppConstants.locationError);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppConstants.locationError);
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
      );

      return (position.latitude, position.longitude);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
