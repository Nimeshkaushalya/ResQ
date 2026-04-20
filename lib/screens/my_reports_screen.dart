import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_flutter/services/emergency_service.dart';
import 'package:resq_flutter/services/chat_service.dart';
import 'package:resq_flutter/screens/chat/chat_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/theme_provider.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final EmergencyService _emergencyService = EmergencyService();

  Future<void> _refreshReports() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'My Emergency Logs',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFFDC2626),
            labelColor: const Color(0xFFDC2626),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(icon: Icon(LucideIcons.hourglass, size: 20), text: 'Pending'),
              Tab(icon: Icon(LucideIcons.siren, size: 20), text: 'Active'),
              Tab(icon: Icon(LucideIcons.checkCircle, size: 20), text: 'History'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _emergencyService.getMyReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data!.docs;
            List<QueryDocumentSnapshot> pending = [];
            List<QueryDocumentSnapshot> active = [];
            List<QueryDocumentSnapshot> history = [];

            for (var doc in docs) {
              final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'pending';
              if (status == 'pending') {
                pending.add(doc);
              } else if (status == 'resolved' || status == 'completed') {
                history.add(doc);
              } else {
                active.add(doc);
              }
            }

            return TabBarView(
              children: [
                _buildLogsList(pending, isDark, false, 'No pending signals'),
                _buildLogsList(active, isDark, true, 'No active responses'),
                _buildLogsList(history, isDark, false, 'No history found'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogsList(List<QueryDocumentSnapshot> reports, bool isDark, bool isActive, String emptyMsg) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.folderOpen, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReports,
      color: const Color(0xFFDC2626),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) => _buildReportCard(reports[index], isDark, isActive),
      ),
    );
  }

  Widget _buildReportCard(QueryDocumentSnapshot doc, bool isDark, bool isActive) {
    final data = doc.data() as Map<String, dynamic>;

    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('h:mm a, MMM d').format(timestamp.toDate())
        : 'Just now';

    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    Color statusColor;
    Color statusBgColor;

    if (isActive) {
      statusColor = Colors.blue.shade600;
      statusBgColor = Colors.blue.withValues(alpha: 0.1);
    } else if (status == 'completed' || status == 'resolved') {
      statusColor = Colors.green.shade600;
      statusBgColor = Colors.green.withValues(alpha: 0.1);
    } else {
      statusColor = Colors.orange.shade600;
      statusBgColor = Colors.orange.withValues(alpha: 0.1);
    }

    IconData typeIcon = LucideIcons.alertTriangle;
    if (data['emergencyType'] == 'Medical') typeIcon = LucideIcons.activity;
    if (data['emergencyType'] == 'Fire') typeIcon = LucideIcons.flame;
    if (data['emergencyType'] == 'Accident') typeIcon = LucideIcons.car;
    if (data['emergencyType'] == 'Crime') typeIcon = LucideIcons.shieldAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.blue.shade300 : (isDark ? Colors.white10 : Colors.transparent),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: const Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['emergencyType'] ?? 'General Emergency',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (data['address'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['address'],
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Text(
                data['description'] ?? 'No description provided.',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 20),
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
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    foregroundColor: Colors.blue.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(LucideIcons.messageCircle, size: 20),
                  label: const Text('Chat with Responder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
