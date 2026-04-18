import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () {
              // Logic to clear all notifications if needed
            },
            icon: const Icon(LucideIcons.checkCheck, size: 20),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login to see notifications'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bellOff, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null 
                        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                        : 'Just now';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: data['isRead'] == true ? Colors.white : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getIconColor(data['type']).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(data['type']),
                            color: _getIconColor(data['type']),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Alert',
                          style: TextStyle(
                            fontWeight: data['isRead'] == true ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['body'] ?? '', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                        onTap: () {
                          // Mark as read
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .doc(doc.id)
                              .update({'isRead': true});
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'emergency': return LucideIcons.siren;
      case 'info': return LucideIcons.info;
      case 'success': return LucideIcons.checkCircle;
      default: return LucideIcons.bell;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'emergency': return const Color(0xFFDC2626);
      case 'success': return Colors.green;
      case 'info': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
