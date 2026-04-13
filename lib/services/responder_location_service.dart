import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ResponderLocationService {
  static final ResponderLocationService _instance = ResponderLocationService._internal();
  factory ResponderLocationService() => _instance;
  ResponderLocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> startLocationSharing() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // First, set status to online
    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': true,
      'isAvailable': true,
    });

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Start listening to location
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen((position) {
      _updateLocationInFirestore(user.uid, position);
    });
  }

  Future<void> stopLocationSharing() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'isAvailable': false,
      });
    }
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateLocationInFirestore(String uid, Position position) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      print('Error updating responder location: $e');
    }
  }

  bool get isSharing => _positionStream != null;
}
