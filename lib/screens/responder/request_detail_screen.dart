import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resq_flutter/services/chat_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isLoading = false;

  Future<void> _acceptRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('emergencies')
          .doc(widget.requestId)
          .update({
        'status': 'accepted',
        'responderId': user.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Fetch responder details for the chat
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final responderName = userDoc.data()?['name'] ?? 'Responder';
      final responderType = userDoc.data()?['responderCategory'] ?? 'Emergency Service';
      
      final userId = widget.requestData['userId'] ?? 'unknown_user';
      final userName = widget.requestData['userName'] ?? 'Citizen';

      // Auto-create Chat
      await ChatService().createChat(
         widget.requestId,
         userId,
         user.uid,
         userName,
         responderName,
         responderType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully!')),
        );
        Navigator.pop(context); // Go back to feed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _callUser(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number provided')),
      );
      return;
    }
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  Future<void> _getDirections(Map<String, dynamic>? dummy) async {
    final double? lat = widget.requestData['latitude'];
    final double? lng = widget.requestData['longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location coordinates provided')),
      );
      return;
    }

    // Construct google maps url
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.requestData;
    print("DEBUG: Request Data contains: ${data.keys.toList()}");
    print("DEBUG: mediaUrls: ${data['mediaUrls']}");

    final String type = data['emergencyType'] ?? data['type'] ?? 'Unknown Emergency';
    final String description = data['description'] ?? 'No detail provided';
    final Timestamp? t = data['createdAt'] ?? data['timestamp'];
    final String? userPhone = data['userPhone'];
    final List<dynamic> mediaUrls = data['mediaUrls'] ?? data['evidence'] ?? [];
    final double? latitude = data['latitude'] ?? (data['location'] != null ? data['location']['latitude'] : null);
    final double? longitude = data['longitude'] ?? (data['location'] != null ? data['location']['longitude'] : null);
    final String status = data['status'] ?? 'pending';

    String timeString = 'Just now';
    if (t != null) {
      timeString = DateFormat('MMM d, yyyy - h:mm a').format(t.toDate());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: status == 'pending'
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == 'pending'
                      ? Colors.orange.shade800
                      : Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Type
            Text(
              type.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Time
            Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  timeString,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Media/Images Section
            const Text(
              'Attached Evidence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (mediaUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(mediaUrls[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: InteractiveViewer(
                                child: Image.network(mediaUrls[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(LucideIcons.imageOff, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text('No visual evidence attached', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Location Mini-Map
            if (latitude != null && longitude != null) ...[
              const Text(
                'Incident Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(latitude, longitude),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.resq_flutter',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(latitude, longitude),
                            width: 50,
                            height: 50,
                            child: const Icon(LucideIcons.mapPin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(LucideIcons.mapPin, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latitude != null
                              ? 'Location Details'
                              : 'No Coordinates',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          data['address'] ?? 'Address information not provided',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Action Buttons
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _acceptRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.checkSquare),
                  label: Text(
                    _isLoading ? 'Accepting...' : 'ACCEPT REQUEST',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callUser(userPhone),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon:
                        const Icon(LucideIcons.phone, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Call User',
                      style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getDirections(null), // The logic now uses internal data
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.navigation,
                        color: Color(0xFF0F172A)),
                    label: const Text(
                      'Directions',
                      style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold),
                    ),
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
