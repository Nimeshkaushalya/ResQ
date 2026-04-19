import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/theme_provider.dart';
import 'request_detail_screen.dart';
import 'package:resq_flutter/screens/chat/chat_screen.dart';
import 'package:resq_flutter/services/chat_service.dart';

class MyAcceptedRequestsScreen extends StatelessWidget {
  const MyAcceptedRequestsScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(docId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Active Responses', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergencies')
            .where('responderId', isEqualTo: user.uid)
            .where('status', whereIn: ['accepted', 'on_the_way', 'arrived'])
            .orderBy('acceptedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState(isDark);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              return _buildRequestCard(context, data, id, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.blue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.activity, size: 64, color: isDark ? Colors.grey.shade600 : Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'No active responses',
            style: TextStyle(
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accept a pending request to see it here.',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> data, String id, bool isDark) {
    final String type = data['emergencyType'] ?? 'Unknown Emergency';
    final String status = data['status'] ?? 'accepted';
    final Timestamp? t = data['createdAt'];
    String timeString = t != null ? DateFormat('h:mm a').format(t.toDate()) : '';

    Color statusColor;
    if (status == 'accepted') statusColor = Colors.orange;
    else if (status == 'on_the_way') statusColor = Colors.blue;
    else if (status == 'arrived') statusColor = Colors.green;
    else statusColor = Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.blue).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  timeString,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.radioReceiver, size: 18, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'STATUS: ${status.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (status == 'accepted' || status == 'on_the_way' || status == 'arrived') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(
                        context, id, 
                        status == 'accepted' ? 'on_the_way' : status == 'on_the_way' ? 'arrived' : 'completed'
                      ),
                      icon: Icon(
                        status == 'accepted' ? LucideIcons.truck : status == 'on_the_way' ? LucideIcons.mapPin : LucideIcons.checkCircle,
                        size: 18,
                      ),
                      label: Text(
                        status == 'accepted' ? 'Mark On The Way' : status == 'on_the_way' ? 'Mark Arrived' : 'Mark Completed',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: id, requestData: data))),
                    icon: Icon(LucideIcons.arrowRight, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    tooltip: 'View Details',
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final chat = await ChatService().getChatByEmergencyId(id);
                      if (chat != null && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat not found for this emergency.')));
                      }
                    },
                    icon: const Icon(LucideIcons.messageCircle, color: Colors.blue),
                    tooltip: 'Open Chat',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
