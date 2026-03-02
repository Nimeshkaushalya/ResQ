import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/services/location_service.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  LatLng? _currentPosition;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _responders = [
    {'id': 1, 'type': 'Ambulance', 'distance': '0.8 km', 'eta': '4 min'},
    {'id': 2, 'type': 'Responder', 'distance': '0.3 km', 'eta': '2 min'},
    {'id': 3, 'type': 'Police', 'distance': '1.2 km', 'eta': '6 min'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }
    } else {
      // Fallback location if permission denied
      if (mounted) {
        setState(() {
          _currentPosition = const LatLng(6.9271, 79.8612); // Colombo
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition ??
                  const LatLng(6.9271, 79.8612), // default Colombo
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.resq_flutter',
              ),
              MarkerLayer(
                markers: [
                  // Current Location (Blue)
                  Marker(
                    point: _currentPosition ?? const LatLng(6.9271, 79.8612),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 32),
                  ),
                  // Dummy Hospital (Red)
                  Marker(
                    point: LatLng(
                        (_currentPosition ?? const LatLng(6.9271, 79.8612))
                                .latitude +
                            0.005,
                        (_currentPosition ?? const LatLng(6.9271, 79.8612))
                                .longitude +
                            0.005),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.local_hospital,
                        color: Colors.red, size: 32),
                  ),
                  // Dummy Responder (Green)
                  Marker(
                    point: LatLng(
                        (_currentPosition ?? const LatLng(6.9271, 79.8612))
                                .latitude -
                            0.003,
                        (_currentPosition ?? const LatLng(6.9271, 79.8612))
                                .longitude -
                            0.004),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.directions_car,
                        color: Colors.green, size: 32),
                  ),
                ],
              ),
            ],
          ),

          // Header Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.only(top: 50, left: 20),
              child: const Text("Nearby Help",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
          ),

          // Responder List sliding up
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Available Responders",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._responders.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.navigation,
                                    size: 18, color: Color(0xFF334155)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['type'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(
                                      "${r['distance']} • ETA ${r['eta']}",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B)),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.phone,
                                    size: 18, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
