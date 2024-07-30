import 'dart:async';
import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class Locationservices {
  static const double centerLat = 23.784433;
  static const double centerLong = 90.397849;
  static const double edgeLat = 23.783081;
  static const double edgeLong = 90.397608;
  static final double radius =
      calculateDistance(centerLat, centerLong, edgeLat, edgeLong);

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  static Future<String> checkLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Location permission denied";
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 3), onTimeout: () {
        throw TimeoutException('Location retrieval timed out');
      });

      double distanceInMeters = calculateDistance(
        centerLat,
        centerLong,
        position.latitude,
        position.longitude,
      );
      String address = await getAddress(position.latitude, position.longitude);
      if (distanceInMeters <= radius) {
        return address;
      } else {
        return "You are outside the office premises $address";
      }
    } catch (e) {
      if (e is TimeoutException) {
        return "Error: Location retrieval timed out";
      }
      return "Error: Unable to get location";
    }
  }

  static Future<String> getAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }
      return "Address not found";
    } catch (e) {
      return "Error: Unable to get address";
    }
  }
}
