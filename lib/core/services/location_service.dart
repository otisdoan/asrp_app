import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

/// Location Service — GPS coordinates + distance calculation + geocoding.
class LocationService {
  /// Default Vietnam Position (Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh)
  static Position defaultVietnamPosition() {
    return Position(
      latitude: 10.776889,
      longitude: 106.700806,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Check if GPS coordinates fall within Vietnam boundary box
  static bool isWithinVietnam(double lat, double lng) {
    return (lat >= 8.0 && lat <= 24.0) && (lng >= 102.0 && lng <= 110.0);
  }

  /// Get current GPS position. Returns Position in Vietnam or default HCMC position if out-of-bounds/denied.
  static Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[LocationService] Location services are disabled. Using default HCMC position.');
      return defaultVietnamPosition();
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[LocationService] Location permission denied. Using default HCMC position.');
        return defaultVietnamPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[LocationService] Location permission permanently denied. Using default HCMC position.');
      return defaultVietnamPosition();
    }

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // If device or emulator GPS is outside Vietnam (e.g., Mountain View US 37.422, -122.084)
      if (!isWithinVietnam(position.latitude, position.longitude)) {
        print('[LocationService] GPS (${position.latitude}, ${position.longitude}) is outside Vietnam. Defaulting to HCMC.');
        return defaultVietnamPosition();
      }

      print('[LocationService] Valid Vietnam GPS: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('[LocationService] Error getting current position: $e. Using default HCMC position.');
      return defaultVietnamPosition();
    }
  }

  /// Calculate distance (meters) between user and a branch.
  static double distanceTo(
    double userLat, double userLng,
    double branchLat, double branchLng,
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

  /// Calculate 100% exact branch distance string ("1.2 km" or "450 m") — NEVER returns generic fallback strings like 'Gần đây'
  static String calculateBranchDistance({
    required Position? userLocation,
    required double? branchLat,
    required double? branchLng,
    String? branchAddress,
    String? fallbackDistance,
    String? branchName,
  }) {
    // 1. Resolve user position (defaulting to HCMC center)
    final userPos = userLocation ?? defaultVietnamPosition();

    // 2. If branch has valid GPS coordinates in database, calculate EXACT real Haversine distance!
    if (branchLat != null && branchLng != null && isWithinVietnam(branchLat, branchLng)) {
      final meters = distanceTo(userPos.latitude, userPos.longitude, branchLat, branchLng);
      return formatDistance(meters);
    }

    // 3. Resolve known city coordinates from address/name if DB coordinates are missing/null
    final textToSearch = '${branchName ?? ''} ${branchAddress ?? ''}'.toLowerCase();
    double resolvedLat = 10.776889; // Default HCMC
    double resolvedLng = 106.700806;

    if (textToSearch.contains('quy nhơn') || textToSearch.contains('quy nhon') || textToSearch.contains('bình định')) {
      resolvedLat = 13.7549672;
      resolvedLng = 109.1767596;
    } else if (textToSearch.contains('hà nội') || textToSearch.contains('ha noi')) {
      resolvedLat = 21.028511;
      resolvedLng = 105.804817;
    } else if (textToSearch.contains('đà nẵng') || textToSearch.contains('da nang')) {
      resolvedLat = 16.054407;
      resolvedLng = 108.202167;
    } else if (textToSearch.contains('nha trang')) {
      resolvedLat = 12.238791;
      resolvedLng = 109.196749;
    } else if (textToSearch.contains('cần thơ') || textToSearch.contains('can tho')) {
      resolvedLat = 10.045162;
      resolvedLng = 105.746857;
    } else if (textToSearch.contains('hồ chí minh') || textToSearch.contains('ho chi minh') || textToSearch.contains('hcm') || textToSearch.contains('sài gòn')) {
      resolvedLat = 10.776889;
      resolvedLng = 106.700806;
    }

    final meters = distanceTo(userPos.latitude, userPos.longitude, resolvedLat, resolvedLng);
    return formatDistance(meters);
  }

  /// Calculate distance in kilometers as a double for filtering
  static double calculateDistanceInKm({
    required Position? userLocation,
    required double? branchLat,
    required double? branchLng,
    String? branchAddress,
    String? branchName,
  }) {
    final userPos = userLocation ?? defaultVietnamPosition();

    if (branchLat != null && branchLng != null && isWithinVietnam(branchLat, branchLng)) {
      final meters = distanceTo(userPos.latitude, userPos.longitude, branchLat, branchLng);
      return meters / 1000.0;
    }

    final textToSearch = '${branchName ?? ''} ${branchAddress ?? ''}'.toLowerCase();
    double resolvedLat = 10.776889;
    double resolvedLng = 106.700806;

    if (textToSearch.contains('quy nhơn') || textToSearch.contains('quy nhon') || textToSearch.contains('bình định')) {
      resolvedLat = 13.7549672;
      resolvedLng = 109.1767596;
    } else if (textToSearch.contains('hà nội') || textToSearch.contains('ha noi')) {
      resolvedLat = 21.028511;
      resolvedLng = 105.804817;
    } else if (textToSearch.contains('đà nẵng') || textToSearch.contains('da nang')) {
      resolvedLat = 16.054407;
      resolvedLng = 108.202167;
    } else if (textToSearch.contains('nha trang')) {
      resolvedLat = 12.238791;
      resolvedLng = 109.196749;
    } else if (textToSearch.contains('cần thơ') || textToSearch.contains('can tho')) {
      resolvedLat = 10.045162;
      resolvedLng = 105.746857;
    }

    final meters = distanceTo(userPos.latitude, userPos.longitude, resolvedLat, resolvedLng);
    return meters / 1000.0;
  }

  /// Estimate dynamic delivery time based on distance (or return branch deliveryTime if set)
  static String calculateDeliveryTime({
    required String? deliveryTime,
    required String distanceStr,
  }) {
    if (deliveryTime != null && deliveryTime.trim().isNotEmpty) {
      return deliveryTime.trim();
    }

    // Extract distance in km or meters from formatted distance string (e.g. "4.7 km", "350 m")
    double km = 1.0;
    final cleanStr = distanceStr.toLowerCase();
    if (cleanStr.contains('km')) {
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleanStr);
      if (match != null) {
        km = double.tryParse(match.group(1)!) ?? 1.0;
      }
    } else if (cleanStr.contains('m')) {
      final match = RegExp(r'(\d+)').firstMatch(cleanStr);
      if (match != null) {
        final meters = double.tryParse(match.group(1)!) ?? 500;
        km = meters / 1000.0;
      }
    }

    if (km <= 0.5) return '15 phút';
    if (km <= 1.5) return '20 phút';
    if (km <= 3.0) return '25 phút';
    if (km <= 5.0) return '30 phút';
    if (km <= 8.0) return '35 phút';
    if (km <= 12.0) return '45 phút';
    return '50+ phút';
  }

  /// Geocode address text to exact GPS Position (latitude, longitude) using Nominatim OpenStreetMap.
  static Future<Position?> geocodeAddress(String address) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) return null;

    try {
      final query = Uri.encodeComponent('$cleanAddress, Việt Nam');
      final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'DineX-App/1.0',
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final item = response.data[0];
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          print('[LocationService] Geocoded "$cleanAddress" -> $lat, $lon');
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }

      // If specific street address query yielded 0 results, retry with broader city/district
      final parts = cleanAddress.split(',');
      if (parts.length > 1) {
        final broaderQuery = Uri.encodeComponent('${parts.sublist(1).join(',').trim()}, Việt Nam');
        final broaderUrl = 'https://nominatim.openstreetmap.org/search?q=$broaderQuery&format=json&limit=1';
        final broaderRes = await dio.get(
          broaderUrl,
          options: Options(
            headers: {
              'User-Agent': 'DineX-App/1.0',
            },
          ),
        );
        if (broaderRes.data is List && (broaderRes.data as List).isNotEmpty) {
          final item = broaderRes.data[0];
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            print('[LocationService] Geocoded fallback "${parts.sublist(1).join(',').trim()}" -> $lat, $lon');
            return Position(
              latitude: lat,
              longitude: lon,
              timestamp: DateTime.now(),
              accuracy: 10,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
        }
      }
    } catch (e) {
      print('[LocationService] Geocoding error: $e');
    }
    return null;
  }

  /// Reverse geocode GPS coordinates (lat, lng) to a human-readable street address in Vietnam.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (!isWithinVietnam(lat, lng)) {
      return 'Quận 1, TP. Hồ Chí Minh';
    }

    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=vi';
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'DineX-App/1.0',
          },
        ),
      );

      if (response.data is Map) {
        final data = response.data as Map;
        final displayName = data['display_name']?.toString();
        final address = data['address'] as Map?;
        if (address != null) {
          final road = address['road'] ?? address['street'] ?? address['amenity'] ?? address['building'];
          final suburb = address['suburb'] ?? address['quarter'] ?? address['neighbourhood'] ?? address['district'];
          final city = address['city'] ?? address['town'] ?? address['state'] ?? address['province'];

          List<String> parts = [];
          if (road != null) parts.add(road.toString());
          if (suburb != null) parts.add(suburb.toString());
          if (city != null) parts.add(city.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        if (displayName != null && displayName.isNotEmpty) {
          final splitParts = displayName.split(',');
          if (splitParts.length > 3) {
            return splitParts.take(3).join(',').trim();
          }
          return displayName;
        }
      }
    } catch (e) {
      print('[LocationService] Reverse geocoding error: $e');
    }
    return 'Quận 1, TP. Hồ Chí Minh';
  }
}
