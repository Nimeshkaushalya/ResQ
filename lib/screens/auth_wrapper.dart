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
import 'package:lucide_icons/lucide_icons.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late final Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = _authService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final User? user = snapshot.data;
        
        print('DEBUG: AuthWrapper State: ${snapshot.connectionState}, User: ${user?.uid}');

        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              final data = docSnapshot.data!.data() as Map<String, dynamic>?;
              final String? role = data?['role'];
              final String? verificationStatus = data?['verificationStatus'];
              
              print('DEBUG: AuthWrapper Firestore Data Found. Role: $role');

              if (role != null) {
                if (role == 'admin') return const AdminMainScaffold();
                
                if (verificationStatus == 'pending') {
                  return const PendingApprovalScreen();
                } else if (verificationStatus == 'rejected') {
                  return const RejectedScreen();
                } else {
                  return role == 'emergency_responder' 
                      ? const ResponderMainScaffold() 
                      : const MainScaffold();
                }
              }
            }

            if (docSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text("Profile Error: ${docSnapshot.error}", textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _authService.signOut(),
                        child: const Text("Sign Out & Try Again"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Still loading or doc doesn't exist yet
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFDC2626)),
                    SizedBox(height: 24),
                    Text("Connecting to ResQ...", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Finalizing your profile data", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
