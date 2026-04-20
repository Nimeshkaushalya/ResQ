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
    String? preferredResponderId,
    String? aiAnalysis,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated.'};
      }

      // Fetch user details from Firestore to get name and phone
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final data = userDoc.data() as Map<String, dynamic>?;

      String userName = data?['username']?.toString() ?? 'Unknown User';
      String userPhone = data?['phoneNumber']?.toString() ?? 'Not provided';

      final String orderId = _generateOrderId();

      // Create Document in Firestore and WAIT for confirmation
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
        'preferredResponderId': preferredResponderId,
        'aiAnalysis': aiAnalysis,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify Emergency Contacts if SOS - only after Firestore is confirmed
      if (emergencyType == 'SOS') {
        final data = userDoc.data() as Map<String, dynamic>?;
        List<dynamic> contacts = data?['emergencyContacts'] ?? [];
        
        if (contacts.isNotEmpty) {
          final firstContact = contacts.first;
          final phone = firstContact['phone']?.toString();
          if (phone != null && phone.isNotEmpty) {
            // Small delay to ensure push notifications and firestore writes are stable
            Future.delayed(const Duration(milliseconds: 1000), () {
               _sendEmergencySMS(phone, userName, address);
            });
          }
        }
      }

      return {
        'success': true,
        'message': '🚨 SIGNAL SENT! Help is on the way.',
        'orderId': orderId
      };
    } catch (e) {
      print('Error submitting emergency report: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('unavailable') || errorMsg.contains('host')) {
        errorMsg = "No Internet! Signal could not reach responders, but SMS will be attempted.";
      }
      return {'success': false, 'message': errorMsg};
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
