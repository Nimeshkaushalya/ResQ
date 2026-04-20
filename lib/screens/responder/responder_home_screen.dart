import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resq_flutter/services/notification_service.dart';
import 'package:resq_flutter/services/location_service.dart';
import 'package:resq_flutter/screens/notifications_screen.dart';
import 'emergency_requests_screen.dart';
import 'my_accepted_requests_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:resq_flutter/services/theme_provider.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  StreamSubscription<QuerySnapshot>? _emergenciesSubscription;
  bool _isInit = true;
  bool _isOnline = false;
  double _rating = 0.0;
  int _totalRatings = 0; 
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
          _rating = (doc.data()?['rating'] ?? 0.0).toDouble();
          _totalRatings = doc.data()?['totalRatings'] ?? 0;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('ResQ Responder', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(LucideIcons.bell, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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
            _buildStatusToggle(isDark),
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
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _totalRatings > 0 
                                ? '${_rating.toStringAsFixed(1)} ($_totalRatings Reviews)' 
                                : 'New (No Ratings)', 
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Live Incidents Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildMiniMap(isDark),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending',
                    stream: FirebaseFirestore.instance
                        .collection('emergencies')
                        .where('status', isEqualTo: 'pending')
                        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))))
                        .snapshots(),
                    icon: LucideIcons.alertCircle,
                    color: const Color(0xFFDC2626),
                    isDark: isDark,
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
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildRecentActivity(user?.uid, isDark),
            const SizedBox(height: 24),
            Text('Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            _buildActionTile(
              'Emergency Queue',
              'View all pending requests',
              LucideIcons.listTodo,
              const Color(0xFFDC2626),
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyRequestsScreen())),
              isDark
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              'My Assignments',
              'Handle current responses',
              LucideIcons.activity,
              const Color(0xFF2563EB),
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAcceptedRequestsScreen())),
              isDark
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFF059669) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade800),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (_isOnline ? const Color(0xFF059669) : Colors.black).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
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

  double _selectedRadius = 10.0; // Default 10km

  Widget _buildMiniMap(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('emergencies').where('status', isEqualTo: 'pending').snapshots(),
                  builder: (context, snapshot) {
                    List<Marker> markers = [];
                    if (snapshot.hasData) {
                      const Distance distance = Distance();
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['latitude'] != null && data['longitude'] != null) {
                          final LatLng incidentPos = LatLng(data['latitude'], data['longitude']);
                          final double km = distance.as(LengthUnit.Kilometer, _lastKnownPos, incidentPos);
                          
                          if (km <= _selectedRadius) {
                            markers.add(Marker(
                              point: incidentPos,
                              width: 40, height: 40,
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyRequestsScreen())),
                                child: Icon(LucideIcons.alertTriangle, color: (data['emergencyType'] == 'SOS') ? Colors.red : Colors.orange, size: 24),
                              ),
                            ));
                          }
                        }
                      }
                    }
                    return FlutterMap(
                      mapController: _miniMapController,
                      options: MapOptions(initialCenter: _lastKnownPos, initialZoom: _selectedRadius <= 5 ? 13 : (_selectedRadius <= 15 ? 11 : 10)),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.resq_flutter'),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _lastKnownPos,
                              radius: _selectedRadius * 1000, // Convert km to meters
                              useRadiusInMeter: true,
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderColor: Colors.blue.withValues(alpha: 0.3),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                        MarkerLayer(markers: [
                          Marker(point: _lastKnownPos, width: 40, height: 40, child: Container(decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(LucideIcons.navigation, color: Colors.blue, size: 20))),
                          ...markers,
                        ]),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Radius Selection Overlay
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black87 : Colors.white).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [5.0, 10.0, 20.0, 50.0].map((r) {
                    bool sel = _selectedRadius == r;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRadius = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFDC2626) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("${r.toInt()}km", 
                          style: TextStyle(color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required Stream<QuerySnapshot> stream, required IconData icon, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)),
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
                  return Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black));
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

  Widget _buildRecentActivity(String? responderId, bool isDark) {
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
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
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
            final Timestamp? t = data['createdAt'];
            String timeString = 'Just now';
            if (t != null) {
              timeString = DateFormat('MMM d, h:mm a').format(t.toDate());
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                            Text(timeString, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                        Text(address, 
                             maxLines: 1, 
                             overflow: TextOverflow.ellipsis,
                             style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return ListTile(
      onTap: onTap,
      tileColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: isDark ? Colors.grey : Colors.grey.shade700),
    );
  }
}
