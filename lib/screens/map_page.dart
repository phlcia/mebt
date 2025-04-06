import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  double _mapBearing = 0.0;
  Position? _userPosition;
  bool _loadingLocation = false;
  
  // Centered on the continental US
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(39.8283, -98.5795),
    zoom: 4,
  );

  @override
  void initState() {
    super.initState();
    _loadCSV();
    _getUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _mapBearing = position.bearing;
    });
  }

  // Get user's current location
  Future<void> _getUserLocation() async {
    setState(() {
      _loadingLocation = true;
    });
    
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied, we cannot request permissions.'),
          ),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _userPosition = position;
        _loadingLocation = false;
      });
      
      // Move camera to user location with appropriate zoom
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 12.0,
          ),
        ),
      );
      
    } catch (e) {
      setState(() {
        _loadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  // Calculate distance between two coordinates in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    // Convert degrees to radians
    double lat1Rad = lat1 * (math.pi / 180);
    double lon1Rad = lon1 * (math.pi / 180);
    double lat2Rad = lat2 * (math.pi / 180);
    double lon2Rad = lon2 * (math.pi / 180);
    
    // Haversine formula
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance;
  }

  // Calculate estimated travel times
  Map<String, String> _calculateTravelTimes(double distanceInMeters) {
    // Average walking speed: 5 km/h = 1.4 m/s
    // Average driving speed: 50 km/h = 13.9 m/s (urban areas)
    
    double walkingTimeInSeconds = distanceInMeters / 1.4;
    double drivingTimeInSeconds = distanceInMeters / 13.9;
    
    String walkingTime = _formatTime(walkingTimeInSeconds);
    String drivingTime = _formatTime(drivingTimeInSeconds);
    
    return {
      'walking': walkingTime,
      'driving': drivingTime,
    };
  }

  // Format time in seconds to a readable format
  String _formatTime(double seconds) {
    if (seconds < 60) {
      return 'Less than 1 minute';
    } else if (seconds < 3600) {
      int minutes = (seconds / 60).round();
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      int hours = (seconds / 3600).floor();
      int minutes = ((seconds % 3600) / 60).round();
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  // Show bottom sheet with distance and travel time info
  void _showLocationInfo(String name, LatLng position) {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for your location...')),
      );
      _getUserLocation();
      return;
    }
    
    double distance = _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    
    Map<String, String> travelTimes = _calculateTravelTimes(distance);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Distance: ${(distance / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_walk),
                  const SizedBox(width: 8),
                  Text(
                    'Walking: ${travelTimes['walking']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_car),
                  const SizedBox(width: 8),
                  Text(
                    'Driving: ${travelTimes['driving']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadCSV() async {
    final data = await rootBundle.loadString('assets/retailers.csv');
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
    
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      final String name = row[0].toString();
      final double? lat = double.tryParse(row[1].toString());
      final double? lng = double.tryParse(row[2].toString());
      
      if (lat != null && lng != null) {
        _markers.add(Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: name),
          onTap: () {
            _showLocationInfo(name, LatLng(lat, lng));
          },
        ));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EBT Locator Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
          if (_loadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}