import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/responder_with_distance.dart';

class LocationService {
  /// Check permissions and get current location
  static Future<Position?> getCurrentLocation() async {
    print('DEBUG: Requesting current location...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('DEBUG: Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('DEBUG: Location permission denied.');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('DEBUG: Location permission denied forever.');
      return null;
    }

    try {
      print('DEBUG: Calling Geolocator.getCurrentPosition...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // More robust
        timeLimit: const Duration(seconds: 10), // Adding a timeout
      );
      print('DEBUG: Successfully got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print("DEBUG: Error getting current position: $e");
      // Fallback to last known position if active fetch fails
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct address string
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty)
          addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          addressParts.add(place.locality!);
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty)
          addressParts.add(place.country!);

        return addressParts.join(', ');
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2
  ) {
    const double radius = 6371; // Earth's radius in km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Get responders within radius
  Future<List<ResponderWithDistance>> getRespondersNearby(
    double userLat,
    double userLon,
    double radiusKm
  ) async {
    try {
      // For real scale, we should use GeoHashing (Geoflutterfire), 
      // but for Day 8 simplicity and current dataset, we'll fetch online responders 
      // and filter by distance.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'emergency_responder')
          .where('isOnline', isEqualTo: true)
          .get();

      List<ResponderWithDistance> nearby = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final location = data['currentLocation'] as Map<String, dynamic>?;

        if (location != null && location['latitude'] != null && location['longitude'] != null) {
          double resLat = (location['latitude'] as num).toDouble();
          double resLon = (location['longitude'] as num).toDouble();
          
          double distance = calculateDistance(userLat, userLon, resLat, resLon);
          
          if (distance <= radiusKm) {
            nearby.add(ResponderWithDistance.fromFirestore(doc, userLat, userLon, distance));
          }
        }
      }

      // Sort by distance (nearest first)
      nearby.sort((a, b) => a.distance.compareTo(b.distance));
      
      return nearby;
    } catch (e) {
      print('Error fetching nearby responders: $e');
      return [];
    }
  }

  /// Get responders nearby as a stream for real-time tracking (Uber-style)
  Stream<List<ResponderWithDistance>> getRespondersNearbyStream(
    double userLat,
    double userLon,
    double radiusKm
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'emergency_responder')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      List<ResponderWithDistance> nearby = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['currentLocation'] as Map<String, dynamic>?;

        if (location != null &&
            location['latitude'] != null &&
            location['longitude'] != null) {
          double resLat = (location['latitude'] as num).toDouble();
          double resLon = (location['longitude'] as num).toDouble();

          double distance = calculateDistance(userLat, userLon, resLat, resLon);

          if (distance <= radiusKm) {
            nearby.add(ResponderWithDistance.fromFirestore(
                doc, userLat, userLon, distance));
          }
        }
      }
      nearby.sort((a, b) => a.distance.compareTo(b.distance));
      return nearby;
    });
  }

  /// Get hospitals within radius
  Future<List<Map<String, dynamic>>> getNearbyHospitals(
    double userLat,
    double userLon,
    double radiusKm
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('hospitals')
          .get();

      List<Map<String, dynamic>> nearby = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['latitude'] != null && data['longitude'] != null) {
          double lat = (data['latitude'] as num).toDouble();
          double lon = (data['longitude'] as num).toDouble();
          
          double distance = calculateDistance(userLat, userLon, lat, lon);
          
          if (distance <= radiusKm) {
            nearby.add({
              ...data,
              'id': doc.id,
              'distance': distance,
            });
          }
        }
      }
      nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return nearby;
    } catch (e) {
      print('Error fetching nearby hospitals: $e');
      return [];
    }
  }

  /// Get police stations within radius
  Future<List<Map<String, dynamic>>> getNearbyPoliceStations(
    double userLat,
    double userLon,
    double radiusKm
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('police_stations')
          .get();

      List<Map<String, dynamic>> nearby = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['latitude'] != null && data['longitude'] != null) {
          double lat = (data['latitude'] as num).toDouble();
          double lon = (data['longitude'] as num).toDouble();
          double distance = calculateDistance(userLat, userLon, lat, lon);
          if (distance <= radiusKm) {
            nearby.add({...data, 'id': doc.id, 'distance': distance});
          }
        }
      }
      nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return nearby;
    } catch (e) {
      return [];
    }
  }

  /// Get fire stations within radius
  Future<List<Map<String, dynamic>>> getNearbyFireStations(
    double userLat,
    double userLon,
    double radiusKm
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('fire_stations')
          .get();

      List<Map<String, dynamic>> nearby = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['latitude'] != null && data['longitude'] != null) {
          double lat = (data['latitude'] as num).toDouble();
          double lon = (data['longitude'] as num).toDouble();
          double distance = calculateDistance(userLat, userLon, lat, lon);
          if (distance <= radiusKm) {
            nearby.add({...data, 'id': doc.id, 'distance': distance});
          }
        }
      }
      nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return nearby;
    } catch (e) {
      return [];
    }
  }

  /// Seed all major Sri Lankan emergency facilities (Hospitals, Police, Fire)
  Future<void> seedAllEmergencyFacilities() async {
    final hospitals = [
      {'name': 'National Hospital of Sri Lanka', 'address': 'Colombo', 'latitude': 6.9195, 'longitude': 79.8687},
      {'name': 'Asiri Medical Hospital', 'address': 'Kirula Rd, Colombo', 'latitude': 6.8856, 'longitude': 79.8732},
      {'name': 'Lanka Hospitals', 'address': 'Elvitigala Mawatha, Colombo', 'latitude': 6.8831, 'longitude': 79.8765},
      {'name': 'Nawaloka Hospital', 'address': 'Colombo 2', 'latitude': 6.9221, 'longitude': 79.8495},
      {'name': 'Lady Ridgeway Hospital', 'address': 'Borella', 'latitude': 6.9168, 'longitude': 79.8734},
      {'name': 'Kandy National Hospital', 'address': 'Kandy', 'latitude': 7.2913, 'longitude': 80.6334},
      {'name': 'Karapitiya Teaching Hospital', 'address': 'Galle', 'latitude': 6.0628, 'longitude': 80.2289},
      {'name': 'Jaffna Teaching Hospital', 'address': 'Jaffna', 'latitude': 9.6644, 'longitude': 80.0195},
      {'name': 'Anuradhapura Teaching Hospital', 'address': 'Anuradhapura', 'latitude': 8.3533, 'longitude': 80.3917},
      {'name': 'Negombo District General Hospital', 'address': 'Negombo', 'latitude': 7.2104, 'longitude': 79.8471},
    ];

    final police = [
      {'name': 'Police Headquarters Colombo', 'address': 'Fort', 'latitude': 6.9341, 'longitude': 79.8483},
      {'name': 'Wellawatte Police Station', 'address': 'Wellawatte', 'latitude': 6.8741, 'longitude': 79.8615},
      {'name': 'Mount Lavinia Police Station', 'address': 'Mt Lavinia', 'latitude': 6.8324, 'longitude': 79.8685},
      {'name': 'Kandy Police Station', 'address': 'Kandy Town', 'latitude': 7.2941, 'longitude': 80.6367},
      {'name': 'Galle Police Station', 'address': 'Galle Fort', 'latitude': 6.0335, 'longitude': 80.2173},
      {'name': 'Jaffna Police Station', 'address': 'Jaffna', 'latitude': 9.6614, 'longitude': 80.0255},
      {'name': 'Negombo Police Station', 'address': 'Negombo', 'latitude': 7.2100, 'longitude': 79.8427},
      {'name': 'Fort Police Station', 'address': 'Colombo Fort', 'latitude': 6.9345, 'longitude': 79.8437},
      {'name': 'Cinnamon Gardens Police Station', 'address': 'Colombo 7', 'latitude': 6.9095, 'longitude': 79.8632},
      {'name': 'Slave Island Police Station', 'address': 'Colombo 2', 'latitude': 6.9208, 'longitude': 79.8519},
    ];

    final fire = [
      {'name': 'Colombo Fire Brigade HQ', 'address': 'Union Place', 'latitude': 6.9214, 'longitude': 79.8621},
      {'name': 'Kandy Fire Brigade', 'address': 'Kandy', 'latitude': 7.2954, 'longitude': 80.6384},
      {'name': 'Galle Fire Brigade', 'address': 'Galle', 'latitude': 6.0367, 'longitude': 80.2114},
      {'name': 'Jaffna Fire Brigade', 'address': 'Jaffna', 'latitude': 9.6687, 'longitude': 80.0152},
      {'name': 'Negombo Fire Brigade', 'address': 'Negombo', 'latitude': 7.2152, 'longitude': 79.8465},
      {'name': 'Battaramulla Fire Station', 'address': 'Battaramulla', 'latitude': 6.8995, 'longitude': 79.9167},
      {'name': 'Dehiwala-Mt Lavinia Fire Brigade', 'address': 'Dehiwala', 'latitude': 6.8456, 'longitude': 79.8742},
      {'name': 'Kurunegala Fire Brigade', 'address': 'Kurunegala', 'latitude': 7.4817, 'longitude': 80.3639},
      {'name': 'Moratuwa Fire Brigade', 'address': 'Moratuwa', 'latitude': 6.7824, 'longitude': 79.8821},
      {'name': 'Gampaha Fire Brigade', 'address': 'Gampaha', 'latitude': 7.0873, 'longitude': 79.9912},
    ];

    final batch = FirebaseFirestore.instance.batch();
    
    // Seed Hospitals
    for (var h in hospitals) {
      final docRef = FirebaseFirestore.instance.collection('hospitals').doc();
      batch.set(docRef, h);
    }
    // Seed Police
    for (var p in police) {
      final docRef = FirebaseFirestore.instance.collection('police_stations').doc();
      batch.set(docRef, p);
    }
    // Seed Fire
    for (var f in fire) {
      final docRef = FirebaseFirestore.instance.collection('fire_stations').doc();
      batch.set(docRef, f);
    }

    await batch.commit();
    print("Emergency facilities seeded successfully!");
  }
}
