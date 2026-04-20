import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_flutter/screens/notifications_screen.dart';
import 'package:resq_flutter/screens/admin/ai_metrics_screen.dart';
import 'package:resq_flutter/screens/admin/emergency_logs_screen.dart';
import 'package:resq_flutter/screens/admin/online_responders_screen.dart';
import 'package:resq_flutter/screens/admin/all_users_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'pending_approvals_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                icon: const Icon(LucideIcons.bell, color: Color(0xFF0F172A)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const SizedBox();
                  if (!snapshot.hasData) return const SizedBox();
                  
                  if (snapshot.data!.docs.isNotEmpty) {
                    return Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('emergencies').snapshots(),
            builder: (context, emergencySnapshot) {
              if (userSnapshot.hasError || emergencySnapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (userSnapshot.connectionState == ConnectionState.waiting || emergencySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = userSnapshot.data?.docs ?? [];
              final emergencies = emergencySnapshot.data?.docs ?? [];
              
              int totalUsers = 0;
              int totalResponders = 0;
              int onlineResponders = 0;
              int pendingApprovals = 0;
              int rejectedUsers = 0;

              for (var userDoc in users) {
                 final data = userDoc.data() as Map<String, dynamic>?;
                 if (data == null) continue;

                 final role = data['role']?.toString() ?? 'user';
                 final status = data['verificationStatus']?.toString() ?? 'approved';
                 final bool isOnline = data['isOnline'] ?? false;
                 
                 if (status == 'rejected') rejectedUsers++;

                 if (role == 'user') {
                   totalUsers++;
                 } else if (role == 'emergency_responder') {
                   totalResponders++;
                   if (isOnline) onlineResponders++;
                   if (status == 'pending') pendingApprovals++;
                 }
              }

              // Emergency Stats
              int emergenciesToday = 0;
              int activeEmergencies = 0;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              for (var emDoc in emergencies) {
                final data = emDoc.data() as Map<String, dynamic>?;
                if (data == null) continue;

                final status = data['status']?.toString() ?? 'pending';
                final Timestamp? createdAt = data['createdAt'] as Timestamp?;

                // Active = not resolved and not completed
                if (status != 'resolved' && status != 'completed') {
                  activeEmergencies++;
                }

                // Today's check
                if (createdAt != null) {
                  final emDate = createdAt.toDate();
                  if (emDate.isAfter(today)) {
                    emergenciesToday++;
                  }
                }
              }

              return RefreshIndicator(
                onRefresh: () async {},
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Status',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      
                      // Row 1: Real-time Platform Stats (Emergencies)
                      const Text('Live Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.4, 
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyLogsScreen())),
                            child: _buildStatCard('Active Now', activeEmergencies.toString(), Icons.emergency, Colors.red, isSmall: true)
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyLogsScreen())),
                            child: _buildStatCard('Today Total', emergenciesToday.toString(), Icons.today, Colors.orange, isSmall: true)
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 2: User Stats
                      const Text('User & Personnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1, 
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen())),
                            child: _buildStatCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue)
                          ),
                          GestureDetector(
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllUsersScreen())),
                             child: _buildStatCard('Total Responders', totalResponders.toString(), Icons.medical_services, Colors.teal)
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineRespondersScreen())),
                            child: _buildStatCard('Online Now', onlineResponders.toString(), Icons.wifi_tethering, Colors.green)
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PendingApprovalsScreen())),
                            child: _buildStatCard('Pending Work', pendingApprovals.toString(), Icons.pending_actions, Colors.deepOrange)
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildStatCard('Rejected Accounts', rejectedUsers.toString(), Icons.cancel_presentation_outlined, Colors.grey, isFullWidth: true),

                      const SizedBox(height: 32),
                      // NEW: System Impact Analysis
                      const Text('System Impact Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade900, Colors.blue.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rescue Success Rate', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text('Year-to-Date Impact', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.analytics, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildImpactMetric('Handled', emergencies.length.toString()),
                                _buildImpactMetric('Rescued', emergencies.where((e) => e['status'] == 'resolved' || e['status'] == 'completed').length.toString()),
                                _buildImpactMetric('Success', "${emergencies.isEmpty ? 0 : ((emergencies.where((e) => e['status'] == 'resolved' || e['status'] == 'completed').length / emergencies.length) * 100).toInt()}%"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      const Text('Approvals & Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.assignment_late, color: Colors.white)),
                    title: const Text('Approvals Management'),
                    subtitle: Text('$pendingApprovals pending • $rejectedUsers rejected'),
                    trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PendingApprovalsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(LucideIcons.brain, color: Colors.white),
                        ),
                        title: const Text('AI Performance Metrics'),
                        subtitle: const Text('View Accuracy, Precision, and user feedback logs'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AIMetricsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImpactMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {bool isFullWidth = false, bool isSmall = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
        child: isFullWidth 
          ? Row(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isSmall ? 22 : 24, color: color),
                SizedBox(height: isSmall ? 4 : 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
