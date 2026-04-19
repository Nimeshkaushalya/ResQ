import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:resq_flutter/screens/settings_screen.dart';

class ResponderProfileScreen extends StatelessWidget {
  const ResponderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final AuthService _authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Responder Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          String username = user?.displayName ?? 'Emergency Responder';
          String email = user?.email ?? 'No email';
          String uniqueId = "RESQ-Loading...";
          String responderType = "Responder";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? username;
            uniqueId = data['uniqueId'] ?? uniqueId;
            responderType = data['responderType'] ?? responderType;
            final String phoneNumber = data['phoneNumber'] ?? 'No phone';
            final int totalResolved = data['totalResolved'] ?? 0;
            final double rating = (data['rating'] ?? 0.0).toDouble();
            final String status = data['verificationStatus'] ?? 'pending';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        child: Icon(LucideIcons.user, size: 50),
                      ),
                      if (status == 'approved')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.verified, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uniqueId,
                    style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 24),

                  // Stats Dashboard
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Cases', totalResolved.toString(), LucideIcons.checkCircle, Colors.green),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatItem('Rating', rating.toStringAsFixed(1), LucideIcons.star, Colors.orange),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _buildStatItem('Type', responderType, LucideIcons.shield, Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account Details
                  _buildSectionTitle('Account Information'),
                  const SizedBox(height: 12),
                  _buildInfoTile(LucideIcons.mail, 'Email', email),
                  _buildInfoTile(LucideIcons.phone, 'Phone', phoneNumber),
                  _buildInfoTile(LucideIcons.shieldCheck, 'Verification', status.toUpperCase()),
                  
                  const SizedBox(height: 24),

                  // App Settings
                  _buildAccountActionTile(LucideIcons.settings, 'App Settings', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                  
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.logOut),
                      label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text("User data not found"));
        },
      ),
    );
  }

  Widget _buildAccountActionTile(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: const Color(0xFF334155)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
