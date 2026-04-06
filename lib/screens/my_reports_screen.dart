import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_flutter/services/emergency_service.dart';
import 'package:resq_flutter/services/chat_service.dart';
import 'package:resq_flutter/screens/chat/chat_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final EmergencyService _emergencyService = EmergencyService();

  Future<void> _refreshReports() async {
    // A small delay to show the refresh animation,
    // StreamBuilder handles the actual fetching in real-time
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshReports,
        color: const Color(0xFFDC2626),
        child: StreamBuilder<QuerySnapshot>(
          stream: _emergencyService.getMyReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFDC2626)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.folderOpen,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No reports found',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 8),
                        Text('Your emergency reports will appear here.',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final timestamp = data['createdAt'] as Timestamp?;
                final dateStr = timestamp != null
                    ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} at ${timestamp.toDate().hour}:${timestamp.toDate().minute}'
                    : 'Just now';

                // Status styling
                final status =
                    (data['status'] ?? 'pending').toString().toLowerCase();
                Color statusColor;
                Color statusBgColor;
                if (status == 'accepted') {
                  statusColor = Colors.blue.shade700;
                  statusBgColor = Colors.blue.shade100;
                } else if (status == 'completed') {
                  statusColor = Colors.green.shade800;
                  statusBgColor = Colors.green.shade100;
                } else {
                  // pending
                  statusColor = Colors.orange.shade800;
                  statusBgColor = Colors.orange.shade100;
                }

                // Type Icon
                IconData typeIcon = LucideIcons.alertTriangle;
                if (data['emergencyType'] == 'Medical') {
                  typeIcon = LucideIcons.activity;
                }
                if (data['emergencyType'] == 'Fire') {
                  typeIcon = LucideIcons.flame;
                }
                if (data['emergencyType'] == 'Accident') {
                  typeIcon = LucideIcons.car;
                }
                if (data['emergencyType'] == 'Crime') {
                  typeIcon = LucideIcons.shieldAlert;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            Text(dateStr,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(typeIcon,
                                  color: const Color(0xFFDC2626), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['emergencyType'] ?? 'General Emergency',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['description'] ?? 'No description provided.',
                          style: const TextStyle(
                              color: Color(0xFF475569), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data['address'] ?? 'Location not available',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (data['mediaUrls'] != null &&
                            (data['mediaUrls'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.paperclip,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text(
                                  '${(data['mediaUrls'] as List).length} Attachment(s)',
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          )
                        ],
                        if (status != 'pending') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final chat = await ChatService().getChatByEmergencyId(doc.id);
                                if (chat != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chat not generated yet.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(LucideIcons.messageCircle, size: 18),
                              label: const Text('Chat with Responder', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
