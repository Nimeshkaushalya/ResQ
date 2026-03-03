import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a random order ID (e.g., RESQ-938472)
  String _generateOrderId() {
    final random = Random();
    final number = random.nextInt(900000) + 100000; // 6 digit number
    return 'RESQ-$number';
  }

  // Submit Emergency Report
  Future<Map<String, dynamic>> submitEmergencyReport({
    required String emergencyType,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required List<String> mediaUrls,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated.'};
      }

      // Fetch user details from Firestore to get name and phone
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      String userName = userDoc.exists && userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['username'] ??
              'Unknown User'
          : 'Unknown User';
      String userPhone = userDoc.exists && userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['phoneNumber'] ??
              'Not provided'
          : 'Not provided';

      final String orderId = _generateOrderId();

      // Create Document in Firestore
      await _firestore.collection('emergencies').add({
        'orderId': orderId,
        'userId': currentUser.uid,
        'userName': userName,
        'userPhone': userPhone,
        'emergencyType': emergencyType,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'mediaUrls': mediaUrls,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Emergency reported successfully.',
        'orderId': orderId
      };
    } catch (e) {
      print('Error submitting emergency report: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get My Reports
  Stream<QuerySnapshot> getMyReports() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('emergencies')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
