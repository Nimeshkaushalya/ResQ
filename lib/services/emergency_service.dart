import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

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
    String? preferredResponderId, // NEW
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
        'preferredResponderId': preferredResponderId, // NEW
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify Emergency Contacts if SOS
      if (emergencyType == 'SOS') {
        List<dynamic> contacts = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['emergencyContacts'] ?? [] : [];
        for (var contact in contacts) {
          final phone = contact['phone'];
          if (phone != null && phone.isNotEmpty) {
            _sendEmergencySMS(phone, userName, address);
          }
        }
      }

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

  Future<void> _sendEmergencySMS(String phoneNumber, String userName, String address) async {
    final String message = "EMERGENCY! $userName has triggered an SOS from ResQ App. Location: $address. Please check on them immediately!";
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      print("Could not launch SMS: $e");
    }
  }
}
