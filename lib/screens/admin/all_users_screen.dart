import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_verification_detail_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.orange;
    if (status == 'rejected') return Colors.red;
    return Colors.green;
  }

  String _getStatusLabel(String status) {
    if (status == 'pending') return 'Pending';
    if (status == 'rejected') return 'Rejected';
    return 'Approved'; // default logic per our simplified auth states
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> allDocs, String filterRole) {
    // 1. Filter by tab role
    List<QueryDocumentSnapshot> filteredList = allDocs;
    if (filterRole != 'all') {
      filteredList = filteredList.where((doc) {
        final role = (doc.data() as Map<String, dynamic>)['role'] ?? 'user';
        return role == filterRole;
      }).toList();
    }

    // 2. Filter by search query
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filteredList = filteredList.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['username'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final uniqueId = (data['uniqueId'] ?? '').toString().toLowerCase();
        
        return name.contains(queryLower) || 
               email.contains(queryLower) || 
               uniqueId.contains(queryLower);
      }).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
           _searchQuery.isNotEmpty ? 'No users found matching "$_searchQuery"' : 'No users found.',
           style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final userDoc = filteredList[index];
        final data = userDoc.data() as Map<String, dynamic>;
        
        final String name = data['username'] ?? 'Unknown User';
        final String email = data['email'] ?? 'No Email';
        final String uniqueId = data['uniqueId'] ?? 'No ID';
        final String role = data['role'] ?? 'user';
        final String status = data['verificationStatus'] ?? 'approved';
        final String? responderType = data['responderType'];
        
        // Skip rendering admin roles in the main directory unless explicitly searched
        if (role == 'admin') return const SizedBox.shrink();

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            leading: CircleAvatar(
              backgroundColor: role == 'emergency_responder' ? Colors.orange.shade100 : Colors.blue.shade100,
              child: Icon(
                role == 'emergency_responder' ? Icons.medical_services : Icons.person,
                color: role == 'emergency_responder' ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$email\nID: $uniqueId', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role == 'emergency_responder' ? (responderType ?? 'Responder') : 'Standard User',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getStatusColor(status).withOpacity(0.5))
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(fontSize: 11, color: _getStatusColor(status), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Responders'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search explicitly by name, email, or Unique ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                   return const Center(child: Text('Error loading users.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                }
                
                final allDocs = snapshot.data!.docs;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(allDocs, 'all'),
                    _buildUserList(allDocs, 'emergency_responder'),
                    _buildUserList(allDocs, 'user'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
