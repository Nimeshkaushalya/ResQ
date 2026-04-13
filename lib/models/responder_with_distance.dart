import 'package:cloud_firestore/cloud_firestore.dart';

class ResponderWithDistance {
  final String uid;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final double distance;
  final String status;
  final double rating;
  final int totalRequests;
  final String? profilePhoto;
  final String? phoneNumber;

  ResponderWithDistance({
    required this.uid,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.status,
    this.rating = 0.0,
    this.totalRequests = 0,
    this.profilePhoto,
    this.phoneNumber,
  });

  factory ResponderWithDistance.fromFirestore(
    DocumentSnapshot doc,
    double userLat,
    double userLon,
    double calculatedDistance,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['currentLocation'] as Map<String, dynamic>?;

    return ResponderWithDistance(
      uid: doc.id,
      name: data['username'] ?? 'Responder',
      type: data['responderType'] ?? 'general',
      latitude: location != null ? (location['latitude'] as num).toDouble() : 0.0,
      longitude: location != null ? (location['longitude'] as num).toDouble() : 0.0,
      distance: calculatedDistance,
      status: data['isAvailable'] == true ? 'Available' : 'Busy',
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0,
      totalRequests: data['totalRequestsCompleted'] != null ? (data['totalRequestsCompleted'] as num).toInt() : 0,
      profilePhoto: data['profilePhoto'],
      phoneNumber: data['phoneNumber'],
    );
  }
}
