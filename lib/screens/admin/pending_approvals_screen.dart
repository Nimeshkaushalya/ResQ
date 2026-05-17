import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'user_verification_detail_screen.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  String _sortBy = 'date'; // 'name' or 'date'

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals Management', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 20),
                      SizedBox(width: 8),
                      Text('Alphabetical'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text('Newest First'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'PENDING', icon: Icon(Icons.pending_actions)),
              Tab(text: 'REJECTED', icon: Icon(Icons.cancel_outlined)),
            ],
            indicatorColor: Color(0xFFDC2626),
            labelColor: Color(0xFFDC2626),
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList('pending'),
            _buildUserList('rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('verificationStatus', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> users = snapshot.data!.docs;

        // Apply Sorting
        users.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          if (_sortBy == 'name') {
            final nameA = (dataA['username'] ?? '').toString().toLowerCase();
            final nameB = (dataB['username'] ?? '').toString().toLowerCase();
            return nameA.compareTo(nameB);
          } else {
            // Newest first
            final dateA = dataA['createdAt'] as Timestamp?;
            final dateB = dataB['createdAt'] as Timestamp?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          }
        });

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.check_circle_outline : Icons.info_outline, 
                  size: 80, 
                  color: status == 'pending' ? Colors.green.shade300 : Colors.grey.shade300
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'pending' ? 'All Clear!' : 'No Rejected Users',
                  style: TextStyle(fontSize: 22, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  status == 'pending' 
                      ? 'No pending approvals required.' 
                      : 'You haven\'t rejected any accounts yet.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final data = userDoc.data() as Map<String, dynamic>?;
            
            if (data == null) return const SizedBox(); // Skip if null

            final String name = data['username']?.toString() ?? 'Unknown User';
            final String email = data['email']?.toString() ?? 'No Email';
            final String uniqueId = data['uniqueId']?.toString() ?? 'No ID';
            final String role = data['role']?.toString() ?? 'user';
            final String? responderType = data['responderType']?.toString();
            final String? note = data['verificationNote']?.toString();
            
            // Format Timestamp
            String formattedDate = 'No date';
            if (data['createdAt'] != null) {
              final Timestamp timestamp = data['createdAt'] as Timestamp;
              formattedDate = DateFormat('MMM d, yyyy • hh:mm a').format(timestamp.toDate());
            }

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200)
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: status == 'rejected' ? Colors.red.shade50 : (role == 'emergency_responder' ? Colors.orange.shade50 : Colors.blue.shade50),
                  child: Icon(
                    status == 'rejected' ? Icons.close : (role == 'emergency_responder' ? Icons.medical_services : Icons.person),
                    color: status == 'rejected' ? Colors.red : (role == 'emergency_responder' ? Colors.orange : Colors.blue),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formattedDate.split(' •')[0], // Just the date part for the top corner
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('$email • $uniqueId', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(formattedDate.split('• ')[1], style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'emergency_responder' ? Colors.orange.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role == 'emergency_responder' ? (responderType ?? 'Responder') : 'Citizen',
                            style: TextStyle(
                              fontSize: 11, 
                              color: role == 'emergency_responder' ? Colors.orange.shade800 : Colors.blue.shade800,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        if (status == 'rejected' && note != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Note: $note",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          )
                        ]
                      ],
                    )
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
        );
      },
    );
  }
}
