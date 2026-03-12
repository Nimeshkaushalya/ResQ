import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserVerificationDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserVerificationDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserVerificationDetailScreen> createState() =>
      _UserVerificationDetailScreenState();
}

class _UserVerificationDetailScreenState extends State<UserVerificationDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateStatus(String status, [String? note]) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = <String, dynamic>{
        'verificationStatus': status,
      };
      
      if (note != null && note.isNotEmpty) {
        updateData['verificationNote'] = note;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User account $status successfully')),
        );
        Navigator.pop(context); // Go back to pending list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRejectDialog() {
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection. This will be shown to the user.'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A reason is required to reject an application')),
                );
                return;
              }
              Navigator.pop(context); // Close dialog
              _updateStatus('rejected', noteController.text.trim());
            },
            child: const Text('Reject User'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            InteractiveViewer(
               panEnabled: true,
               minScale: 0.5,
               maxScale: 4,
               child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 300,
                      child: Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                  ),
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    final Map<String, dynamic>? docs =
        widget.userData['documents'] as Map<String, dynamic>?;

    if (docs == null || docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No documents uploaded.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    final role = widget.userData['role'];
    
    // Check if this was a dev skip
    if (docs['devSkip'] == 'true') {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DEV OVERRIDE: This user skipped verification via development tools.',
                  style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Uploaded Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (docs.containsKey('nicFront') && docs['nicFront'] != 'dummy_url')
          _buildDocumentTile(
            role == 'user' ? 'ID / License (Front)' : 'Work ID Details',
            docs['nicFront'],
          ),
        if (docs.containsKey('nicBack') && docs['nicBack'] != 'dummy_url')
          _buildDocumentTile(
            role == 'user' ? 'ID / License (Back)' : 'Additional Document',
             docs['nicBack'],
          ),
        if (docs.containsKey('certificate') && docs['certificate'] != 'dummy_url')
          _buildDocumentTile('Professional Certificate', docs['certificate']),
          
        // Fallback for dummy URLs to show they exist but aren't real images
        if (docs.containsValue('dummy_url'))
           Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Note: Some documents contain dummy URLs (likely from a Dev Skip or bypassed validation).',
                    style: TextStyle(color: Colors.amber.shade900)),
                  ),
                ],
              ),
           )
      ],
    );
  }

  Widget _buildDocumentTile(String title, String url) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.image, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.fullscreen),
        onTap: () => _showImageDialog(title, url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.userData['username'] ?? 'Unknown User';
    final String email = widget.userData['email'] ?? 'No Email';
    final String phone = widget.userData['phoneNumber'] ?? 'No Phone';
    final String uniqueId = widget.userData['uniqueId'] ?? 'No ID';
    final String role = widget.userData['role'] ?? 'user';
    final String? responderType = widget.userData['responderType'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Approve $name'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: role == 'emergency_responder'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        role == 'emergency_responder'
                            ? Icons.medical_services
                            : Icons.person,
                        size: 40,
                        color: role == 'emergency_responder'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: role == 'emergency_responder'
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: role == 'emergency_responder'
                                ? Colors.orange.shade200
                                : Colors.blue.shade200),
                      ),
                      child: Text(
                        role == 'emergency_responder'
                            ? (responderType ?? 'Responder')
                            : 'Standard User',
                        style: TextStyle(
                          fontSize: 14,
                          color: role == 'emergency_responder'
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Account Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.email, 'Email', email),
                  _buildDetailRow(Icons.phone, 'Phone', phone),
                  _buildDetailRow(Icons.badge, 'Unique ID', uniqueId),
                  const SizedBox(height: 16),
                  const Divider(),
                  _buildDocumentSection(),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _showRejectDialog,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateStatus('approved'),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
