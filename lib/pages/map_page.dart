import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
const MapPage({super.key});




@override
State<MapPage> createState() => _MapPageState();
}




class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  double _mapBearing = 0.0;
  Position? _userPosition;
  bool _loadingLocation = false;
  
  // San Diego centered position
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(32.7157, -117.1611), // San Diego coordinates
    zoom: 12,
  );

  // Hardcoded EBT locations in San Diego
  final List<Map<String, dynamic>> _sanDiegoLocations = [
    {
      'name': 'Northgate Market',
      'latitude': 32.7160,
      'longitude': -117.1298,
      'type': 'Grocery Store'
    },
    {
      'name': 'Food4Less',
      'latitude': 32.7077,
      'longitude': -117.1532,
      'type': 'Grocery Store'
    },
    {
      'name': 'Walmart Neighborhood Market',
      'latitude': 32.7391,
      'longitude': -117.0837,
      'type': 'Grocery Store'
    },
    {
      'name': 'Family Dollar',
      'latitude': 32.7020,
      'longitude': -117.1441,
      'type': 'Convenience Store'
    },
    {
      'name': 'Vons',
      'latitude': 32.7492,
      'longitude': -117.1303,
      'type': 'Grocery Store'
    },
    {
      'name': 'Target',
      'latitude': 32.7675,
      'longitude': -117.1558,
      'type': 'Superstore'
    },
    {
      'name': 'Farmers Market',
      'latitude': 32.7316,
      'longitude': -117.1517,
      'type': 'Fresh Produce'
    },
  ];

  @override
  void initState() {
    super.initState();
    _addSanDiegoMarkers();
    _getUserLocation();
  }

  void _addSanDiegoMarkers() {
    Set<Marker> tempMarkers = {};
    
    for (int i = 0; i < _sanDiegoLocations.length; i++) {
      final location = _sanDiegoLocations[i];
      
      tempMarkers.add(
        Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(
            location['latitude'],
            location['longitude'],
          ),
          // Using the default marker with green color for EBT locations
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: location['type'],
          ),
          onTap: () {
            _showLocationInfo(
              location['name'],
              location['type'],
              LatLng(
                location['latitude'],
                location['longitude'],
              ),
            );
          },
        ),
      );
    }
    
    setState(() {
      _markers = tempMarkers;
    });
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
          setState(() {
            _loadingLocation = false;
          });
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
        setState(() {
          _loadingLocation = false;
        });
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
            zoom: 13.0,
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
  void _showLocationInfo(String name, String type, LatLng position) {
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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // EBT Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'EBT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Distance info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Distance: ${(distance / 1000).toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Estimated Travel Time:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Walking time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Walking: ${travelTimes['walking']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Driving time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Driving: ${travelTimes['driving']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Just close for now - in a real app you'd launch directions
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Getting directions...')),
                        );
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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