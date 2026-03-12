import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_verification_detail_screen.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingUsers = snapshot.data!.docs;

          if (pendingUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: TextStyle(fontSize: 24, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no pending approvals at the moment.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refreshing is mainly cosmetic as it's a real-time stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pendingUsers.length,
              itemBuilder: (context, index) {
                final userDoc = pendingUsers[index];
                final data = userDoc.data() as Map<String, dynamic>;
                
                final String name = data['username'] ?? 'Unknown User';
                final String email = data['email'] ?? 'No Email';
                final String uniqueId = data['uniqueId'] ?? 'No ID';
                final String role = data['role'] ?? 'user';
                final String? responderType = data['responderType'];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: role == 'emergency_responder' ? Colors.orange.shade100 : Colors.blue.shade100,
                      child: Icon(
                        role == 'emergency_responder' ? Icons.medical_services : Icons.person,
                        color: role == 'emergency_responder' ? Colors.orange.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('$email • $uniqueId'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: role == 'emergency_responder' ? Colors.orange.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: role == 'emergency_responder' ? Colors.orange.shade200 : Colors.blue.shade200)
                              ),
                              child: Text(
                                role == 'emergency_responder' ? (responderType ?? 'Responder') : 'Standard User',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: role == 'emergency_responder' ? Colors.orange.shade700 : Colors.blue.shade700,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserVerificationDetailScreen(
                            userId: userDoc.id,
                            userData: data,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
