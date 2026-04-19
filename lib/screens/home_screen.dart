import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/theme_provider.dart';
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
                await FirebaseFirestore.instance.collection('emergencies').doc(emergencyId).update({'isRated': true, 'rating': selectedRating});

                final resDoc = await FirebaseFirestore.instance.collection('users').doc(responderId).get();
                final currentRating = (resDoc.data()?['rating'] ?? 5.0).toDouble();
                final totalRatings = (resDoc.data()?['totalRatings'] ?? 0) + 1;
                final newRating = ((currentRating * (totalRatings - 1)) + selectedRating) / totalRatings;

                await FirebaseFirestore.instance.collection('users').doc(responderId).update({
                  'rating': newRating,
                  'totalRatings': totalRatings,
                  'totalResolved': FieldValue.increment(1),
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

  double _selectedRadius = 10.0; // Default 10km

  Future<void> _loadNearbyCount() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final responders = await LocationService().getRespondersNearby(
          position.latitude,
          position.longitude,
          _selectedRadius,
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.siren, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(themeProvider.t('app_title'),
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                icon: Icon(LucideIcons.bell, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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
              _buildNearbyMapBanner(context, isDark),
              const SizedBox(height: 24),
              
              Text(
                themeProvider.t('emergency_question'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                themeProvider.t('sos_instruction'),
                style: TextStyle(color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
  
              const Center(
                child: SOSButton(),
              ),
              const SizedBox(height: 32),
 
              Row(
                children: [
                  Expanded(
                    child: _buildHotlineCard(
                      themeProvider.t('police'), 
                      "119", 
                      LucideIcons.shieldAlert, 
                      const Color(0xFF1E3A8A), 
                      () => _launchCaller("119", themeProvider)
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHotlineCard(
                      themeProvider.t('ambulance'), 
                      "1990", 
                      LucideIcons.heart, 
                      const Color(0xFFDC2626), 
                      () => _launchCaller("1990", themeProvider)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
  
              Text(
                themeProvider.t('report_incident'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      context, themeProvider.t('medical'), LucideIcons.stethoscope, Colors.blue, isDark),
                  _buildEmergencyCard(
                      context, themeProvider.t('fire'), LucideIcons.flame, Colors.orange, isDark),
                  _buildEmergencyCard(
                      context, themeProvider.t('accident'), LucideIcons.car, Colors.purple, isDark),
                  _buildEmergencyCard(
                      context, themeProvider.t('crime'), LucideIcons.shieldAlert, Colors.red, isDark),
                ],
              ),
              const SizedBox(height: 32),
  
              _buildFirstAidBanner(context, isDark),
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
              color: color.withValues(alpha: 0.3),
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

  Future<void> _launchCaller(String number, ThemeProvider themeProvider) async {
    final Uri url = Uri.parse('tel:$number');
    
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

  Widget _buildNearbyMapBanner(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
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
                colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                            "$_nearbyCount responders active within ${_selectedRadius.toInt()}km",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white70)
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [5.0, 10.0, 20.0, 50.0].map((r) {
              bool sel = _selectedRadius == r;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRadius = r;
                    _isLoadingCount = true;
                  });
                  _loadNearbyCount();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade300)),
                  ),
                  child: Text(
                    "${r.toInt()}km Range",
                    style: TextStyle(
                      color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFirstAidBanner(BuildContext context, bool isDark) {
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
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.red.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.05),
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
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bookOpen,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "First Aid Guide",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Step-by-step offline emergency guides",
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B), fontSize: 13),
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
      BuildContext context, String title, IconData icon, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReportScreen(initialType: title)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
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
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: _isHolding ? 0.5 : 0.3),
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
