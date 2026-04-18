import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  static Future<List<Map<String, dynamic>>> fetchNearbyEmergencyPlaces(LatLng position) async {
    const double radius = 5000;
    final String query = '[out:json][timeout:25];('
        'nwr["amenity"~"hospital|police|fire_station|clinic"](around:$radius,${position.latitude},${position.longitude});'
        'nwr["healthcare"="hospital"](around:$radius,${position.latitude},${position.longitude});'
        ');out center;';

    // Using a stable Swiss mirror
    final String url = 'https://overpass.osm.ch/api/interpreter?data=${Uri.encodeComponent(query)}';
    print('DEBUG: Calling Overpass API (Swiss Mirror)...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      print('DEBUG: Overpass Status Code: ${response.statusCode}');

      List<Map<String, dynamic>> places = [];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        print('DEBUG: Found ${elements.length} emergency elements from OSM');

        for (var element in elements) {
          double? lat = element['lat'] ?? element['center']?['lat'];
          double? lon = element['lon'] ?? element['center']?['lon'];
          
          if (lat != null && lon != null) {
            Map<String, dynamic> tags = element['tags'] ?? {};
            String type = tags['amenity'] ?? tags['healthcare'] ?? 'unknown';
            
            String defaultName = 'Emergency Facility';
            if (type == 'hospital') defaultName = 'Hospital';
            else if (type == 'police') defaultName = 'Police Station';
            else if (type == 'fire_station') defaultName = 'Fire Station';
            else if (type == 'clinic') defaultName = 'Medical Clinic';

            String name = tags['name'] ?? defaultName;
            
            places.add({
              'name': name,
              'lat': lat,
              'lon': lon,
              'type': type,
            });
          }
        }
      }

      // FALLBACK: If still empty or 504, add major SL hospitals manually so the map is NEVER empty
      if (places.isEmpty) {
        print('DEBUG: No results from API, using fallback major emergency locations');
        places.addAll([
          {'name': 'Colombo South Teaching Hospital (Kalubowila)', 'lat': 6.8669, 'lon': 79.8845, 'type': 'hospital'},
          {'name': 'Colombo General Hospital', 'lat': 6.9200, 'lon': 79.8687, 'type': 'hospital'},
          {'name': 'Sri Jayawardenepura General Hospital', 'lat': 6.8928, 'lon': 79.9194, 'type': 'hospital'},
          {'name': 'National Hospital of Sri Lanka', 'lat': 6.9189, 'lon': 79.8703, 'type': 'hospital'},
          {'name': 'Mount Lavinia Police Station', 'lat': 6.8324, 'lon': 79.8647, 'type': 'police'},
          {'name': 'Kohuwala Police Station', 'lat': 6.8688, 'lon': 79.8946, 'type': 'police'},
          {'name': 'Dehiwala Police Station', 'lat': 6.8522, 'lon': 79.8672, 'type': 'police'},
          {'name': 'Narahenpita Fire Station', 'lat': 6.9038, 'lon': 79.8824, 'type': 'fire_station'},
        ]);
      }

      return places;
    } catch (e) {
      print('Error fetching places: $e');
      // Final static fallback on catch
      return [
        {'name': 'Colombo South Teaching Hospital', 'lat': 6.8669, 'lon': 79.8845, 'type': 'hospital'},
        {'name': 'Police Headquarters Colombo', 'lat': 6.9344, 'lon': 79.8492, 'type': 'police'},
      ];
    }
  }
}
