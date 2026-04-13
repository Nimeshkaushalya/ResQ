import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/screens/report_screen.dart';
import 'package:resq_flutter/services/location_service.dart';
import 'package:resq_flutter/screens/first_aid_guide_screen.dart';
import 'package:resq_flutter/screens/live_responders_map_screen.dart';
import 'package:resq_flutter/services/emergency_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _nearbyCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyCount();
  }

  Future<void> _loadNearbyCount() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final responders = await LocationService().getRespondersNearby(
          position.latitude,
          position.longitude,
          5.0,
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
                child: GestureDetector(
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Triggering Instant SOS... Please wait.'), duration: Duration(seconds: 2)),
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
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626), // red-600
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bell, size: 56, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            "SOS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
  
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
                        "$_nearbyCount responders active within 5km",
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
