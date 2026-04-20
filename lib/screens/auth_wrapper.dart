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
import 'complete_profile_screen.dart';

/// The top-level wrapper that listens to Auth state changes.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;

          if (user == null) {
            return const LoginScreen();
          }

          // User is authenticated, now route them based on their status
          return UserStatusRouter(user: user);
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// A specialized router that handles Firestore document logic and redirects.
class UserStatusRouter extends StatelessWidget {
  final User user;
  const UserStatusRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        // 1. Initial State: No document or missing role -> Send to Complete Profile
        if (data == null || data['role'] == null) {
          return CompleteProfileScreen(user: user);
        }

        final String role = data['role']?.toString() ?? 'user';
        final String status = data['verificationStatus']?.toString() ?? 'pending';

        // 2. Admin Logic (Admins bypass verification)
        if (role == 'admin') return const AdminMainScaffold();

        // 3. Status Check (Strict: only 'approved' can enter)
        if (status == 'approved') {
          if (role == 'emergency_responder') {
            return const ResponderMainScaffold();
          }
          return const MainScaffold();
        } 
        
        // 4. Handle Rejected State
        if (status == 'rejected') {
          return const RejectedScreen();
        }

        // 5. Default: If status is 'pending' or anything else, show Pending screen
        return const PendingApprovalScreen();
      },
    );
  }
}
