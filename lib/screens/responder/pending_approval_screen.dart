import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isResetting = false;

  void _reApply() async {
    setState(() => _isResetting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'verificationStatus': FieldValue.delete(),
          'role': FieldValue.delete(),
          'documentsSubmitted': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile reset. You can now re-apply.')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFDE7E7),
      appBar: AppBar(
        title: const Text('Account Status', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Color(0xFF0F172A)),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final String status = data?['verificationStatus'] ?? 'pending';
          final String? rejectionNote = data?['verificationNote'];
          
          bool isRejected = status == 'rejected';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.2), blurRadius: 30)],
                    ),
                    child: Icon(
                      isRejected ? LucideIcons.xCircle : LucideIcons.checkCircle,
                      size: 80,
                      color: isRejected ? Colors.red : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Text(
                    isRejected ? 'Application Rejected' : 'Verification In Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    isRejected 
                      ? 'Your application was not approved by the administrator. Please review the reason below and re-apply.'
                      : 'We have received your documents and are currently reviewing them. This process usually takes 24 hours. Hang tight!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
                  ),
                  
                  if (isRejected && rejectionNote != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.alertCircle, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('REJECTION REASON', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(rejectionNote, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  
                  if (isRejected) 
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _isResetting ? null : _reApply,
                        icon: _isResetting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.uploadCloud),
                        label: const Text('RE-SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                         const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
                         const SizedBox(height: 24),
                         Text("Waiting for admin approval...", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ],
                    ),
                    
                  const SizedBox(height: 32),
                  
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(LucideIcons.logOut, size: 20),
                    label: const Text('Access Different Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
