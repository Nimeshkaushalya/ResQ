import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/services/location_service.dart';
import 'package:resq_flutter/services/places_service.dart';
import 'package:resq_flutter/models/responder_with_distance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _isLoading = false;
  List<ResponderWithDistance> _responders = [];
  bool _isListExpanded = true;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _openDirections(double lat, double lon) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    if (mounted) setState(() => _isLoading = true);
    
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
        });
        print('DEBUG: Moving map to $latLng');
        _mapController.move(latLng, 14.0);
        
        print('DEBUG: Calling PlacesService.fetchNearbyEmergencyPlaces...');
        final places = await PlacesService.fetchNearbyEmergencyPlaces(latLng);
        
        final responders = await LocationService().getRespondersNearby(
          latLng.latitude, 
          latLng.longitude, 
          5.0
        );

        if (mounted) {
          setState(() {
            _nearbyPlaces = places;
            _responders = responders;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentPosition = const LatLng(6.9271, 79.8612);
        });
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final mapPosition = _currentPosition ?? const LatLng(6.9271, 79.8612);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapPosition,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.resq_flutter',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: mapPosition,
                    radius: 5000, 
                    useRadiusInMeter: true,
                    color: Colors.red.withOpacity(0.05),
                    borderColor: Colors.red.withOpacity(0.2),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: mapPosition,
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
                        const Icon(Icons.circle, color: Colors.white, size: 18),
                        const Icon(Icons.circle, color: Colors.blue, size: 14),
                      ],
                    ),
                  ),

                  ..._nearbyPlaces.map((place) => Marker(
                    point: LatLng(place['lat'], place['lon']),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      place['type'] == 'hospital' ? Icons.local_hospital : Icons.local_police,
                                      color: place['type'] == 'hospital' ? Colors.red : Colors.blue.shade900,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        place['name'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _openDirections(place['lat'], place['lon']),
                                  icon: const Icon(Icons.directions, color: Colors.white),
                                  label: const Text('Get Directions', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        place['type'] == 'hospital' 
                            ? Icons.local_hospital 
                            : (place['type'] == 'fire_station' 
                                ? Icons.fire_truck 
                                : (place['type'] == 'clinic' ? Icons.medical_services : Icons.local_police)),
                        color: place['type'] == 'hospital' 
                            ? Colors.red 
                            : (place['type'] == 'fire_station' 
                                ? Colors.orange 
                                : (place['type'] == 'clinic' ? Colors.redAccent : Colors.blue.shade900)),
                        size: 30,
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

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

          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isListExpanded = !_isListExpanded),
                  child: Container(
                    width: 70,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                      ],
                    ),
                    child: Icon(
                      _isListExpanded ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                if (_isListExpanded)
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 15),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Help',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                '${_responders.length + _nearbyPlaces.length} nearby',
                                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: (_responders.isEmpty && _nearbyPlaces.isEmpty)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.userX, size: 40, color: Colors.grey[300]),
                                      const SizedBox(height: 10),
                                      const Text('No help nearby.', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  children: [
                                    if (_responders.isNotEmpty) ...[
                                      const Text("Responders", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 10),
                                      ..._responders.map((res) => _buildListTile(
                                        name: res.name,
                                        subtitle: res.type.replaceAll('_', ' '),
                                        distance: res.distance,
                                        icon: LucideIcons.user,
                                        color: const Color(0xFFDC2626),
                                        lat: res.latitude,
                                        lon: res.longitude,
                                      )),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_nearbyPlaces.isNotEmpty) ...[
                                      const Text("Medical & Safety Facilities", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 10),
                                      ..._nearbyPlaces.map((place) {
                                        double dist = 0.0;
                                        if (_currentPosition != null) {
                                          dist = _calculateDistance(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                            place['lat'],
                                            place['lon']
                                          );
                                        }
                                        return _buildListTile(
                                          name: place['name'],
                                          subtitle: place['type'].toString().toUpperCase(),
                                          distance: dist,
                                          icon: place['type'] == 'hospital' ? Icons.local_hospital : Icons.local_police,
                                          color: place['type'] == 'hospital' ? Colors.red : Colors.blue.shade900,
                                          lat: place['lat'],
                                          lon: place['lon'],
                                        );
                                      }),
                                    ]
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _isListExpanded ? MediaQuery.of(context).size.height * 0.35 : 0),
        child: FloatingActionButton(
          onPressed: _fetchLocation,
          backgroundColor: const Color(0xFFDC2626),
          child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String name,
    required String subtitle,
    required double distance,
    required IconData icon,
    required Color color,
    required double lat,
    required double lon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
            const Text('Tap for Route', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        onTap: () => _openDirections(lat, lon),
      ),
    );
  }
}
