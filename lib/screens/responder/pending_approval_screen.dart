import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isUploading = false;

  void _uploadDocument() async {
    // For now, let's simulate document upload to Firestore
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // In a real app, you'd use ImagePicker and Firebase Storage
        // Here we'll just update a flag to say documents are submitted
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'documentsSubmitted': true,
          'verificationStatus': 'pending', // Keep as pending but marked as submitted
          'documents': {
            'id_card': 'uploaded_placeholder_url',
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documents submitted successfully! Waiting for admin review.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Pending'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final bool docSubmitted = data?['documentsSubmitted'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  docSubmitted ? LucideIcons.clock : LucideIcons.fileWarning,
                  size: 80,
                  color: docSubmitted ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  docSubmitted ? 'Admin Review Pending' : 'Action Required: Verification',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  docSubmitted
                      ? 'We are currently reviewing your submitted documents. This process usually takes 24-48 hours.'
                      : 'To act as an Emergency Responder, we need to verify your identity. Please upload a clear photo of your NIC or Professional ID.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                if (!docSubmitted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _uploadDocument,
                            icon: const Icon(LucideIcons.uploadCloud),
                            label: const Text('Upload NIC / Proof of Identity'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Still under review. Please check back later.')),
                        );
                      },
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Check Status'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                    },
                    icon: const Icon(LucideIcons.logOut),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Contact Support'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
