import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:resq_flutter/services/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();
    
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allGranted 
            ? "All essential permissions granted!" 
            : "Some permissions were denied. Please enable them in system settings for full app functionality."),
          backgroundColor: allGranted ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy & Data Usage"),
        content: const SingleChildScrollView(
          child: Text(
            "ResQ values your privacy. We only access your location during an active emergency report or when you are 'Online' as a responder. \n\n"
            "Camera and Microphone are used exclusively for evidence collection during reports.\n\n"
            "Your data is securely stored on Firebase and is never shared with third parties without your consent during an emergency response.",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("I Understand")),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    // Step 1: First confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        content: Text(
          'This will permanently delete your account and all your emergency report history. This action CANNOT be undone.\n\nAre you absolutely sure?',
          style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 2: Show loading and delete
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626))),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        // Delete Firebase Auth account
        await user.delete();
        // Sign out Google session so re-login is treated as truly fresh
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.'), backgroundColor: Colors.red),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Firebase requires re-authentication for sensitive operations
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign out and sign in again before deleting your account.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Notifications", isDark),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.bell,
              title: "Push Notifications",
              subtitle: "Received alerts for emergencies",
              trailing: Switch(
                value: themeProvider.notificationsEnabled,
                onChanged: (val) => themeProvider.setNotifications(val),
                activeThumbColor: const Color(0xFFDC2626),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Appearance", isDark),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.moon,
              title: "Dark Mode",
              subtitle: "Optimize for night viewing",
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                activeThumbColor: const Color(0xFFDC2626),
              ),
            ),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.languages,
              title: "App Language",
              subtitle: "Choose your preferred language",
              trailing: DropdownButton<String>(
                value: themeProvider.language,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                underline: const SizedBox(),
                items: ['English', 'සිංහල', 'தமிழ்'].map((String lang) {
                  return DropdownMenuItem<String>(
                    value: lang,
                    child: Text(lang, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) themeProvider.setLanguage(val);
                },
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader("Privacy & Security", isDark),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.lock,
              title: "Privacy Policy",
              subtitle: "How we handle your data",
              onTap: _showPrivacyPolicy,
            ),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.shieldCheck,
              title: "Permissions",
              subtitle: "Manage device access",
              onTap: _requestPermissions,
            ),

            const SizedBox(height: 32),
            _buildSectionHeader("About", isDark),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.info,
              title: "App Version",
              subtitle: "v1.0.0 (Stable)",
              onTap: null,
            ),
            _buildSettingTile(
              isDark: isDark,
              icon: LucideIcons.heart,
              title: "Developer Info",
              subtitle: "ResQ Engineering Team",
              onTap: null,
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Danger Zone", isDark),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A0A0A) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
              ),
              child: ListTile(
                onTap: _deleteAccount,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                ),
                title: const Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                subtitle: Text('Permanently erase all your data', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.red),
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2026 ResQ Emergency Response",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFF43F5E), size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B), fontSize: 12)),
        trailing: trailing ?? Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white54 : Colors.grey),
      ),
    );
  }
}
