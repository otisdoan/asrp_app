import 'package:geolocator/geolocator.dart';

/// Location Service — GPS coordinates + distance calculation.
/// Business: lấy vị trí user → tính khoảng cách đến chi nhánh.
/// Follows RULE: không cần API key, không cần geocoding.
class LocationService {
  /// Get current GPS position. Returns Position or null if denied.
  static Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // GPS coordinates retrieved
    return position;
  }

  /// Calculate distance (meters) between user and a branch.
  static double distanceTo(
    double userLat,
    double userLng,
    double branchLat,
    double branchLng,
  ) {
    return Geolocator.distanceBetween(userLat, userLng, branchLat, branchLng);
  }

  /// Format distance for display: "1.2 km" or "350 m"
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }
}
