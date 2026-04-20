import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserVerificationDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData; // Keep for initial data while loading

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
  bool _isProcessing = false;

  Future<void> _updateStatus(String status, [String? note]) async {
    setState(() => _isProcessing = true);
    try {
      if (status == 'rejected') {
        // As per user request: Rejection = Permanent Deletion from system
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account rejected and deleted permanently.')));
          Navigator.pop(context);
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'verificationStatus': status,
        if (note != null) 'verificationNote': note,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User account $status successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Reason for rejection', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (noteController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _updateStatus('rejected', noteController.text.trim());
            },
            child: const Text('Reject'),
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
          children: [
            AppBar(title: Text(title), automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
            InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection(Map<String, dynamic> data) {
    final Map<String, dynamic>? docs = data['documents'] as Map<String, dynamic>?;
    if (docs == null || docs.isEmpty) return const Text('No documents uploaded.');

    final List<dynamic>? certificates = docs['certificates'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Uploaded Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        if (docs['nicFront'] != null) _buildDocumentTile('NIC Front Side', docs['nicFront']),
        if (docs['nicBack'] != null) _buildDocumentTile('NIC Back Side', docs['nicBack']),
        
        // Multiple certificates support
        if (certificates != null && certificates.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Professional Certificates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          ...certificates.asMap().entries.map((entry) {
            return _buildDocumentTile('Certificate ${entry.key + 1}', entry.value.toString());
          }).toList(),
        ] else if (docs['certificate'] != null) // Fallback for old single-cert structure
          _buildDocumentTile('Professional Certificate', docs['certificate']),
      ],
    );
  }

  Widget _buildDocumentTile(String title, String url) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.image, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.fullscreen),
        onTap: () => _showImageDialog(title, url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify User')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading user.'));
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User document not found or deleted.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text('User data is empty.'));
          
          final String name = data['username']?.toString() ?? 'No Name';
          final String role = data['role']?.toString() ?? 'user';
          final String email = data['email']?.toString() ?? 'No Email';
          final String phone = data['phoneNumber']?.toString() ?? 'No Phone';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(radius: 40, child: Icon(role == 'emergency_responder' ? Icons.medical_services : Icons.person, size: 40)),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(email)),
                ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(phone)),
                const Divider(),
                _buildDocumentSection(data),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _isProcessing ? null : _showRejectDialog, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), child: const Text('REJECT', style: TextStyle(color: Colors.red)))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: _isProcessing ? null : () => _updateStatus('approved'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('APPROVE', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }
}
