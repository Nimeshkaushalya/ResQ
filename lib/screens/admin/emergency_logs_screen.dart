import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmergencyLogsScreen extends StatelessWidget {
  const EmergencyLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Logs', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFDC2626),
            labelColor: Color(0xFFDC2626),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.emergency_share), text: 'Pending'),
              Tab(icon: Icon(Icons.directions_run), text: 'Active'),
              Tab(icon: Icon(Icons.archive), text: 'Archive'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmergencyList(statusGroup: 'pending'),
            EmergencyList(statusGroup: 'active'),
            EmergencyList(statusGroup: 'archive'),
          ],
        ),
      ),
    );
  }
}

class EmergencyList extends StatelessWidget {
  final String statusGroup;
  const EmergencyList({super.key, required this.statusGroup});

  @override
  Widget build(BuildContext context) {
        final now = DateTime.now();
        final twelveHoursAgo = now.subtract(const Duration(hours: 12));
        
        List<String> statuses = [];
        if (statusGroup == 'pending') {
          statuses = ['pending'];
        } else if (statusGroup == 'active') {
          statuses = ['accepted', 'on_the_way', 'arrived'];
        } else {
          statuses = ['resolved', 'completed', 'cancelled'];
        }

        Query query = FirebaseFirestore.instance.collection('emergencies')
            .where('status', whereIn: statuses);
            
        // Filter by time
        if (statusGroup == 'pending' || statusGroup == 'active') {
          query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(twelveHoursAgo));
        } else {
          // Archive shows items up to 30 days old
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo));
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: query.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldCheck, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No records found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final doc = logs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final String type = data['emergencyType'] ?? 'SOS';
            final String name = data['userName'] ?? 'Unknown';
            final String address = data['address'] ?? 'No location';
            final Timestamp? time = data['createdAt'] as Timestamp?;
            final String formattedTime = time != null 
                ? DateFormat('MMM d, hh:mm a').format(time.toDate()) 
                : 'Unknown time';

            final String currentStatus = data['status'] ?? 'pending';

            Color statusColor;
            switch(currentStatus) {
              case 'pending': statusColor = Colors.red; break;
              case 'accepted': 
              case 'on_the_way':
              case 'arrived':
                statusColor = Colors.blue; break;
              case 'resolved':
              case 'completed':
                statusColor = Colors.green; break;
              case 'cancelled':
                statusColor = Colors.grey; break;
              default: statusColor = Colors.blueGrey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    type == 'SOS' ? Icons.warning_amber : Icons.medical_information,
                    color: statusColor,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                    Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('User: $name', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(address, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    if (statusGroup == 'active') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentStatus == 'arrived' ? Colors.green.shade50 : Colors.blue.shade50, 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          currentStatus == 'accepted' ? 'Responder heading to scene' : 
                          currentStatus == 'on_the_way' ? 'Responder is on the way' : 'Responder has arrived',
                          style: TextStyle(
                            fontSize: 11, 
                            color: currentStatus == 'arrived' ? Colors.green.shade900 : Colors.blue.shade900, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ]
                  ],
                ),
                onTap: () => _showDetails(context, data),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Request Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _detailRow('ID', data['orderId'] ?? 'N/A'),
              _detailRow('Type', data['emergencyType'] ?? 'SOS'),
              _detailRow('Description', data['description'] ?? 'No description'),
              _detailRow('User', data['userName'] ?? 'Unknown'),
              _detailRow('Contact', data['userPhone'] ?? 'N/A'),
              _detailRow('Location', data['address'] ?? 'N/A'),
              
              if (data['responderId'] != null) ...[
                const Divider(height: 32),
                const Text('Assigned Responder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 16),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(data['responderId']).get(),
                  builder: (context, resSnapshot) {
                    if (resSnapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (!resSnapshot.hasData || !resSnapshot.data!.exists) {
                      return const Text('Responder data not found');
                    }
                    
                    final resData = resSnapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        _detailRow('Name', resData['username'] ?? resData['fullName'] ?? 'Unknown'),
                        _detailRow('Expertise', resData['responderType'] ?? 'Emergency Responder'),
                        _detailRow('Contact', resData['email'] ?? 'N/A'),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
