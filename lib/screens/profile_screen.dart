import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _authService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          String username = "User";
          // Check if data exists
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? 'User';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(LucideIcons.user,
                      size: 40, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Blood Type: O+",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),

                // Stats
                Row(
                  children: [
                    _buildStatCard("Reports", "12"),
                    const SizedBox(width: 16),
                    _buildStatCard("Rescued", "2"),
                  ],
                ),

                const SizedBox(height: 24),

                // Settings
                _buildMenuItem(LucideIcons.settings, "Settings"),
                _buildMenuItem(LucideIcons.history, "History"),
                _buildMenuItem(
                  LucideIcons.logOut,
                  "Logout",
                  isDestructive: true,
                  onTap: () async {
                    await _authService.signOut();
                    // Navigation handled by AuthWrapper
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626))),
            Text(label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label,
      {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? Colors.red : const Color(0xFF334155)),
      title: Text(
        label,
        style: TextStyle(
            color: isDestructive ? Colors.red : const Color(0xFF334155),
            fontWeight: FontWeight.w500),
      ),
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
