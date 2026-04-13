import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // The StreamBuilder automatically updates
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;
          
          int totalUsers = 0;
          int totalResponders = 0;
          int pendingApprovals = 0;
          int approvedResponders = 0;

          for (var userDoc in users) {
             final data = userDoc.data() as Map<String, dynamic>;
             final role = data['role'] ?? 'user';
             final status = data['verificationStatus'] ?? 'approved';
             
             if (role == 'user') {
               totalUsers++;
             } else if (role == 'emergency_responder') {
               totalResponders++;
               if (status == 'pending') {
                 pendingApprovals++;
               } else if (status == 'approved') {
                 approvedResponders++;
               }
             }
          }

          return RefreshIndicator(
            onRefresh: () async {
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is the current platform status',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9, // Taller cards to prevent overflow
                    children: [
                      _buildStatCard(
                        'Total Users',
                        totalUsers.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Responders',
                        totalResponders.toString(),
                        Icons.medical_services,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Pending Approvals',
                        pendingApprovals.toString(),
                        Icons.pending_actions,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Approved Responders',
                        approvedResponders.toString(),
                        Icons.verified_user,
                        Colors.green,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.assignment_late, color: Colors.white),
                    ),
                    title: const Text('Review Pending Approvals'),
                    subtitle: Text('$pendingApprovals accounts require your attention'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                   
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
