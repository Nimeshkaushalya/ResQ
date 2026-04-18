import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:resq_flutter/services/location_service.dart';
import 'package:resq_flutter/services/notification_service.dart';
import 'package:resq_flutter/services/emergency_service.dart';
import 'package:resq_flutter/screens/notifications_screen.dart';
import 'package:resq_flutter/screens/report_screen.dart';
import 'package:resq_flutter/screens/first_aid_guide_screen.dart';
import 'package:resq_flutter/screens/live_responders_map_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _nearbyCount = 0;
  bool _isLoadingCount = true;

  StreamSubscription<QuerySnapshot>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadNearbyCount();
    _setupStatusListener();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _setupStatusListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('emergencies')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>;
        final String status = data['status'] ?? '';
        final bool isRated = data['isRated'] ?? false;
        final String? responderId = data['responderId'];

        if (change.type == DocumentChangeType.modified) {
          if (status == 'accepted') {
            _notifyUser('Help is on the way! ✅', 'A responder is heading your way.', type: 'emergency');
          } else if (status == 'resolved' && !isRated && responderId != null) {
            _showRatingDialog(change.doc.id, responderId);
            _notifyUser('Emergency Resolved', 'Please rate your experience with the responder.', type: 'success');
          }
        }
      }
    });
  }

  void _notifyUser(String title, String body, {String type = 'info'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Save to Firestore for NotificationsScreen
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    // 2. Show push notification
    NotificationService().showLocalNotification(title, body);
  }

  void _showRatingDialog(String emergencyId, String responderId) {
    double selectedRating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate your Responder', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was the emergency assistance?', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = index + 1.0),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Update Emergency Doc
                await FirebaseFirestore.instance.collection('emergencies').doc(emergencyId).update({'isRated': true, 'rating': selectedRating});

                // Update Responder Rating (Simple average logic)
                final resDoc = await FirebaseFirestore.instance.collection('users').doc(responderId).get();
                final currentRating = (resDoc.data()?['rating'] ?? 5.0).toDouble();
                final totalRatings = (resDoc.data()?['totalRatings'] ?? 0) + 1;
                final newRating = ((currentRating * (totalRatings - 1)) + selectedRating) / totalRatings;

                await FirebaseFirestore.instance.collection('users').doc(responderId).update({
                  'rating': newRating,
                  'totalRatings': totalRatings,
                  'totalResolved': FieldValue.increment(1), // Real increment
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNearbyCount() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final responders = await LocationService().getRespondersNearby(
          position.latitude,
          position.longitude,
          10.0,
        );
        if (mounted) {
          setState(() {
            _nearbyCount = responders.length;
            _isLoadingCount = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.siren, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text('ResQ',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
          ],
        ),
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
              // Optional: Add a simple badge if there are unread notifications
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
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
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
      body: RefreshIndicator(
        onRefresh: _loadNearbyCount,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Find Nearby Help Section (Uber Style)
              _buildNearbyMapBanner(context),
              const SizedBox(height: 24),
              
              // Welcome Section
              const Text(
                "Are you in an emergency?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A), // Slate-900
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Press the SOS button or select an emergency type below.",
                style: TextStyle(color: Color(0xFF64748B)), // Slate-500
              ),
              const SizedBox(height: 32),
  
              // SOS Button
              Center(
                child: SOSButton(),
              ),
              const SizedBox(height: 32),

              // Quick Emergency Call Buttons (119 & 1990)
              Row(
                children: [
                  Expanded(
                    child: _buildHotlineCard(
                      "Police", 
                      "119", 
                      LucideIcons.shieldAlert, 
                      const Color(0xFF1E3A8A), // Indigo-900
                      () => _launchCaller("119")
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHotlineCard(
                      "Ambulance", 
                      "1990", 
                      LucideIcons.heart, 
                      const Color(0xFFDC2626), // Red-600
                      () => _launchCaller("1990")
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
  
              // Emergency Grid
              const Text(
                "Report Incident",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
  
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildEmergencyCard(
                      context, 'Medical', LucideIcons.stethoscope, Colors.blue),
                  _buildEmergencyCard(
                      context, 'Fire', LucideIcons.flame, Colors.orange),
                  _buildEmergencyCard(
                      context, 'Accident', LucideIcons.car, Colors.purple),
                  _buildEmergencyCard(
                      context, 'Crime', LucideIcons.shieldAlert, Colors.red),
                ],
              ),
              const SizedBox(height: 32),
  
              // First Aid Guide Button
              _buildFirstAidBanner(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineCard(String title, String number, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCaller(String number) async {
    final Uri url = Uri.parse('tel:$number');
    
    // Safety Confirmation Dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.phone, color: Color(0xFFDC2626)),
              const SizedBox(width: 12),
              const Text('Confirm Call'),
            ],
          ),
          content: Text('Are you sure you want to dial $number? This will connect you directly to official emergency services.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (!await launchUrl(url)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch dialer for $number')),
                    );
                  }
                }
              },
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNearbyMapBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LiveRespondersMapScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.map, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Find Nearby Help",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoadingCount 
                    ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                    : Text(
                        "$_nearbyCount responders active within 10km",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white70)
          ],
        ),
      ),
    );
  }

  Widget _buildFirstAidBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FirstAidGuideScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626), // red-600
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookOpen,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "First Aid Guide",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Step-by-step offline emergency guides",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
      BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReportScreen(initialType: title)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSOS();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    _controller.reset();
    setState(() => _isHolding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚨 SOS TRIGGERED! Fetching location...'), backgroundColor: Colors.red),
    );

    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      String? address = await LocationService.getAddressFromCoordinates(position.latitude, position.longitude);
      
      final result = await EmergencyService().submitEmergencyReport(
        emergencyType: 'SOS',
        description: 'Immediate Critical Medical Emergency! Auto-generated SOS.',
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? 'Unknown Location',
        mediaUrls: [],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location. Please check GPS settings.'), backgroundColor: Colors.red,),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isHolding = true);
        _controller.forward();
      },
      onLongPressEnd: (_) {
        setState(() => _isHolding = false);
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
      },
      onLongPressCancel: () {
        setState(() => _isHolding = false);
        _controller.reverse();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Progress ring
          SizedBox(
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                );
              },
            ),
          ),
          // Main Button
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(_isHolding ? 0.5 : 0.3),
                  blurRadius: _isHolding ? 40 : 20,
                  spreadRadius: _isHolding ? 10 : 5,
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.shieldAlert, size: 48, color: Colors.white),
                   SizedBox(height: 8),
                   Text(
                    "HOLD FOR SOS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
