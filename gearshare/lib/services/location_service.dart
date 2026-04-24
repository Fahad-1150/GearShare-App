import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Get the current user position
  Future<Position?> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        return position;
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Uses the Haversine formula via latlong2 package
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const distance = Distance();
    final distanceInMeters = distance(LatLng(lat1, lon1), LatLng(lat2, lon2));
    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Get distance between a position and a coordinate point
  double? getDistanceFromPosition(
    Position? userPosition,
    double? targetLatitude,
    double? targetLongitude,
  ) {
    if (userPosition == null ||
        targetLatitude == null ||
        targetLongitude == null) {
      return null;
    }

    return calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }
}
