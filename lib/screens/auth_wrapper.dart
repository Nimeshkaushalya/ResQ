import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_scaffold.dart';
import 'responder/responder_main_scaffold.dart';
import 'responder/pending_approval_screen.dart';
import 'responder/rejected_screen.dart';
import 'admin/admin_main_scaffold.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        print('DEBUG: Auth State Connection: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          print('DEBUG: Current User UID: ${user?.uid}');

          if (user == null) {
            print('DEBUG: No user found, showing LoginScreen');
            return const LoginScreen();
          }

          // Listen to the user's Firestore document to get the role in real time
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, docSnapshot) {
              print(
                  'AuthWrapper StreamBuilder state: ${docSnapshot.connectionState}');

              if (docSnapshot.hasError) {
                print('AuthWrapper Error: ${docSnapshot.error}');
              }

              if (docSnapshot.connectionState == ConnectionState.waiting) {
                print('AuthWrapper waiting...');
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                // The document hasn't been created yet (during sign up race condition)
                print('AuthWrapper doc not found yet...');
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final data = docSnapshot.data!.data() as Map<String, dynamic>?;
              final String? role = data?['role'];
              final String? verificationStatus = data?['verificationStatus'];

              print(
                  'AuthWrapper Role found: $role, Status: $verificationStatus');

              if (role == 'admin') {
                return const AdminMainScaffold();
              }

              if (verificationStatus == 'pending') {
                return const PendingApprovalScreen();
              } else if (verificationStatus == 'rejected') {
                return const RejectedScreen();
              } else {
                if (role == 'emergency_responder') {
                  return const ResponderMainScaffold();
                } else {
                  return const MainScaffold();
                }
              }
            },
          );
        }

        // Waiting for connection
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
