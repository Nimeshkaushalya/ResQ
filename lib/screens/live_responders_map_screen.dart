import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../models/responder_with_distance.dart';
import '../widgets/responder_card.dart';
import '../services/chat_service.dart';
import 'chat/chat_screen.dart';
import 'report_screen.dart';

class LiveRespondersMapScreen extends StatefulWidget {
  const LiveRespondersMapScreen({super.key});

  @override
  State<LiveRespondersMapScreen> createState() => _LiveRespondersMapScreenState();
}

class _LiveRespondersMapScreenState extends State<LiveRespondersMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final double _radiusKm = 10.0;
  
  Position? _currentPosition;
  List<ResponderWithDistance> _nearbyResponders = [];
  List<Map<String, dynamic>> _nearbyHospitals = [];
  List<Map<String, dynamic>> _nearbyPolice = []; // NEW
  List<Map<String, dynamic>> _nearbyFire = []; // NEW
  String _selectedFilter = 'all'; 
  bool _isLoading = true;
  bool _hasMovedToInitialLocation = false;
  bool _isMapReady = false; // NEW FLAG
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ResponderWithDistance>>? _respondersStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _respondersStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadStaticFacilities() async {
    if (_currentPosition == null) return;

    final hospitals = await _locationService.getNearbyHospitals(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _radiusKm,
    );

    final police = await _locationService.getNearbyPoliceStations(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _radiusKm,
    );

    final fire = await _locationService.getNearbyFireStations(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _radiusKm,
    );

    if (mounted) {
      setState(() {
        _nearbyHospitals = hospitals;
        _nearbyPolice = police;
        _nearbyFire = fire;
      });
    }
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _loadStaticFacilities();
        
        // Listen to Responders in Real-time
        _respondersStream = _locationService.getRespondersNearbyStream(
          position.latitude,
          position.longitude,
          _radiusKm,
        ).listen((responders) {
           if (mounted) {
             setState(() {
               _nearbyResponders = responders;
               _isLoading = false;
             });
           }
        });
        
        // Listen for user location changes
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _currentPosition = pos;
            });
            if (!_hasMovedToInitialLocation && _isMapReady) {
              _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
              _hasMovedToInitialLocation = true;
            }
          }
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ResponderWithDistance> get _filteredResponders {
    if (_selectedFilter == 'all') return _nearbyResponders;
    return _nearbyResponders.where((r) => r.type.toLowerCase() == _selectedFilter).toList();
  }

  void _showResponderDetails(ResponderWithDistance responder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResponderCard(
        responder: responder,
        onChat: () async {
          final chatId = await ChatService().getChatByEmergencyId(responder.uid); // Simplified link
          // If no chat exists, we could create one or show a message
          if (chatId != null && mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chatId)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active chat with this responder.')));
          }
        },
        onRequest: () {
          // Navigate to Report Screen with pre-selected responder
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportScreen(
                initialType: 'Emergency',
                preSelectedResponderId: responder.uid,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getMarkerIcon(String type) {
    IconData iconData;
    Color color;

    switch (type.toLowerCase()) {
      case 'ambulance':
        iconData = LucideIcons.truck;
        color = Colors.red;
        break;
      case 'police':
        iconData = LucideIcons.shield;
        color = Colors.blue;
        break;
      case 'fire':
        iconData = LucideIcons.flame;
        color = Colors.orange;
        break;
      case 'volunteer':
        iconData = LucideIcons.user;
        color = Colors.purple;
        break;
      case 'hospital':
        iconData = LucideIcons.plus;
        color = Colors.red;
        break;
      default:
        iconData = LucideIcons.helpCircle;
        color = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(iconData, size: 20, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Help Map", style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.database, size: 20),
            tooltip: 'Seed All Facilities',
            onPressed: () async {
              await _locationService.seedAllEmergencyFacilities();
              _loadStaticFacilities();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hospitals, Police, and Fire Stations seeded!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadStaticFacilities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentPosition?.latitude ?? 6.9271,
                          _currentPosition?.longitude ?? 79.8612,
                        ),
                        initialZoom: 14.0,
                        onMapReady: () {
                          setState(() {
                            _isMapReady = true;
                          });
                          // Move to position if already have it
                          if (_currentPosition != null && !_hasMovedToInitialLocation) {
                            _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0);
                            _hasMovedToInitialLocation = true;
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.resq_flutter',
                        ),
                    // Radius Circle
                    CircleLayer(
                      circles: [
                        if (_currentPosition != null)
                          CircleMarker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            radius: _radiusKm * 1000, // in meters
                            useRadiusInMeter: true,
                            color: Colors.blue.withOpacity(0.1),
                            borderColor: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2,
                          ),
                      ],
                    ),
                    // Markers Layer
                    MarkerLayer(
                      markers: [
                        // User position
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(LucideIcons.circleDot, color: Colors.blue, size: 24),
                              ],
                            ),
                          ),
                        // Hospital positions
                        if (_selectedFilter == 'all' || _selectedFilter == 'hospital')
                          ..._nearbyHospitals.map((h) => Marker(
                                point: LatLng(h['latitude'], h['longitude']),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showFacilityDetails(h, 'hospital'),
                                  child: _getMarkerIcon('hospital'),
                                ),
                              )),
                        // Police positions
                        if (_selectedFilter == 'all' || _selectedFilter == 'police')
                          ..._nearbyPolice.map((p) => Marker(
                                point: LatLng(p['latitude'], p['longitude']),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showFacilityDetails(p, 'police'),
                                  child: _getMarkerIcon('police'),
                                ),
                              )),
                        // Fire positions
                        if (_selectedFilter == 'all' || _selectedFilter == 'fire')
                          ..._nearbyFire.map((f) => Marker(
                                point: LatLng(f['latitude'], f['longitude']),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showFacilityDetails(f, 'fire'),
                                  child: _getMarkerIcon('fire'),
                                ),
                              )),
                        // Responder positions
                        ..._filteredResponders.map((r) => Marker(
                              point: LatLng(r.latitude, r.longitude),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showResponderDetails(r),
                                child: _getMarkerIcon(r.type),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
                
                // Top Filter Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All'),
                        _buildFilterChip('ambulance', 'Ambulance'),
                        _buildFilterChip('police', 'Police'),
                        _buildFilterChip('fire', 'Fire'),
                        _buildFilterChip('hospital', 'Hospitals'),
                        _buildFilterChip('volunteer', 'Volunteer'),
                      ],
                    ),
                  ),
                ),
                
                // Bottom count overlay
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Text(
                          "${_nearbyResponders.length} Responders nearby within 5km",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: const Color(0xFFDC2626).withOpacity(0.2),
        checkmarkColor: const Color(0xFFDC2626),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFDC2626) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _showFacilityDetails(Map<String, dynamic> facility, String type) {
    IconData icon;
    Color color;
    if (type == 'police') { icon = LucideIcons.shield; color = Colors.blue; }
    else if (type == 'fire') { icon = LucideIcons.flame; color = Colors.orange; }
    else { icon = LucideIcons.plus; color = Colors.red; }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    facility['name'] ?? 'Facility',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(facility['address'] ?? 'No address provided'),
            const SizedBox(height: 8),
            Text("Distance: ${facility['distance'].toStringAsFixed(1)} km"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=${facility['latitude']},${facility['longitude']}';
                      launchUrl(Uri.parse(url));
                    },
                    icon: const Icon(LucideIcons.navigation),
                    label: const Text("Get Directions"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
