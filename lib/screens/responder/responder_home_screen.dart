import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resq_flutter/services/notification_service.dart';
import 'package:resq_flutter/services/location_service.dart';
import 'package:resq_flutter/screens/notifications_screen.dart';
import 'emergency_requests_screen.dart';
import 'my_accepted_requests_screen.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  StreamSubscription<QuerySnapshot>? _emergenciesSubscription;
  bool _isInit = true;
  bool _isOnline = false;
  double _rating = 4.8; 
  LatLng _lastKnownPos = const LatLng(6.9271, 79.8612); 
  final MapController _miniMapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _setupEmergencyListener();
    _updateLocation();
  }

  void _updateLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _lastKnownPos = LatLng(pos.latitude, pos.longitude);
      });
      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'currentLocation': {
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          }
        });
      }
    }
  }

  void _fetchStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _isOnline = doc.data()?['isOnline'] ?? false;
          _rating = (doc.data()?['rating'] ?? 4.8).toDouble();
        });
      }
    }
  }

  void _toggleOnline(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': value,
      });
      setState(() {
        _isOnline = value;
      });
      if (value) _updateLocation();
    }
  }

  @override
  void dispose() {
    _emergenciesSubscription?.cancel();
    super.dispose();
  }

  void _setupEmergencyListener() {
    _emergenciesSubscription = FirebaseFirestore.instance
        .collection('emergencies')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (_isInit) {
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null && now.difference(createdAt).inMinutes < 5) {
              if (_isOnline) _showNewEmergencyNotification(data);
            }
          } else {
            if (_isOnline) _showNewEmergencyNotification(data);
          }
        }
      }
      if (_isInit) _isInit = false;
    });
  }

  void _showNewEmergencyNotification(Map<String, dynamic> data) {
    final type = data['emergencyType'] ?? 'Emergency';
    final address = data['address'] ?? 'Nearby';
    NotificationService().showLocalNotification(
      '🚨 NEW ALERT: $type',
      'Someone needs help at $address. Open app to view details.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ResQ Responder'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Color(0xFF0F172A)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusToggle(),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFDC2626),
                  child: Text(
                    (user?.displayName != null && user!.displayName!.isNotEmpty)
                        ? user.displayName!.substring(0, 1).toUpperCase()
                        : 'R',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Emergency Responder',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('$_rating Rating', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Live Incidents Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildMiniMap(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending',
                    stream: FirebaseFirestore.instance.collection('emergencies').where('status', isEqualTo: 'pending').snapshots(),
                    icon: LucideIcons.alertCircle,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: 'My Active',
                    stream: FirebaseFirestore.instance
                        .collection('emergencies')
                        .where('responderId', isEqualTo: user?.uid)
                        .where('status', whereIn: ['accepted', 'on_the_way', 'arrived']).snapshots(),
                    icon: LucideIcons.activity,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildRecentActivity(user?.uid),
            const SizedBox(height: 24),
            const Text('Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildActionTile(
              'Emergency Queue',
              'View all pending requests',
              LucideIcons.listTodo,
              const Color(0xFFDC2626),
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyRequestsScreen())),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              'My Assignments',
              'Handle current responses',
              LucideIcons.activity,
              const Color(0xFF2563EB),
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAcceptedRequestsScreen())),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFF059669) : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (_isOnline ? const Color(0xFF059669) : Colors.black).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_isOnline ? LucideIcons.zap : LucideIcons.zapOff, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isOnline ? 'ONLINE' : 'OFFLINE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_isOnline ? 'You are visible to victims' : 'Go online to receive alerts', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeColor: Colors.white,
            activeTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    return Container(
      height: 180,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('emergencies').where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, snapshot) {
            List<Marker> markers = [];
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['latitude'] != null) {
                  markers.add(Marker(
                    point: LatLng(data['latitude'], data['longitude']),
                    child: const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                  ));
                }
              }
            }
            return FlutterMap(
              mapController: _miniMapController,
              options: MapOptions(center: _lastKnownPos, zoom: 12, interactiveFlags: InteractiveFlag.none),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.resq_flutter',
                ),
                MarkerLayer(markers: [
                  Marker(point: _lastKnownPos, child: const Icon(LucideIcons.navigation, color: Colors.blue, size: 20)),
                  ...markers,
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required Stream<QuerySnapshot> stream, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(String? responderId) {
    if (responderId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergencies')
          .where('responderId', isEqualTo: responderId)
          .where('status', isEqualTo: 'resolved')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text('No recent activity to show', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['emergencyType'] ?? 'Emergency';
            final address = data['address'] ?? 'Unknown location';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(address, 
                             maxLines: 1, 
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
    );
  }
}
