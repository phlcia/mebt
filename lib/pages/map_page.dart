import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'dart:math' show pi;
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _filteredMarkers = {};
  double _mapBearing = 0.0;
  bool _isLoading = true;
  String _searchText = '';
  List<Map<String, dynamic>> _storeData = [];
  
  // Default to center of US, will be updated with user location
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(39.8283, -98.5795),
    zoom: 4,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition().then((position) {
      if (position != null) {
        setState(() {
          _initialPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 12,
          );
        });
      }
      _loadCSV();
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _mapBearing = position.bearing;
    });
  }

  Future<void> _loadCSV() async {
    try {
      // Load the CSV file from assets
      final data = await rootBundle.loadString('assets/retailers.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
      
      // Get header row
      final headers = csvTable[0].map((header) => header.toString()).toList();
      
      // Use BitmapDescriptor for marker icon
      final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/ebt_marker.png', // Create this asset or use default marker
      ).catchError((error) {
        return BitmapDescriptor.defaultMarker;
      });

      // Process data rows
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        
        // Create a map of the store data
        Map<String, dynamic> storeInfo = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          storeInfo[headers[j]] = row[j];
        }
        
        final String name = row[0].toString();
        final double? lat = double.tryParse(row[1].toString());
        final double? lng = double.tryParse(row[2].toString());
        
        // Add to store data list
        if (lat != null && lng != null) {
          storeInfo['latitude'] = lat;
          storeInfo['longitude'] = lng;
          storeInfo['position'] = LatLng(lat, lng);
          _storeData.add(storeInfo);
          
          // Create marker
          _markers.add(
            Marker(
              markerId: MarkerId('marker_$i'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: storeInfo.containsKey('address') ? storeInfo['address'].toString() : null,
              ),
              icon: customIcon,
            ),
          );
        }
      }
      
      setState(() {
        _isLoading = false;
        _filteredMarkers = _markers;
      });
    } catch (e) {
      print('Error loading CSV: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading store data: $e')),
      );
    }
  }
  
  void _filterMarkers(String query) {
    setState(() {
      _searchText = query;
      if (query.isEmpty) {
        _filteredMarkers = _markers;
      } else {
        _filteredMarkers = _markers.where((marker) {
          final String title = marker.infoWindow.title ?? '';
          final String snippet = marker.infoWindow.snippet ?? '';
          return title.toLowerCase().contains(query.toLowerCase()) ||
              snippet.toLowerCase().contains(query.toLowerCase());
        }).toSet();
      }
    });
  }
  
  void _centerOnUserLocation() async {
    final Position? position = await _determinePosition();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EBT Store Locator'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Google Map widget displaying markers
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            markers: _filteredMarkers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Sticky, rounded search bar at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for EBT stores',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: _filterMarkers,
              ),
            ),
          ),

          // Results counter
          if (_searchText.isNotEmpty)
            Positioned(
              top: 70,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_filteredMarkers.length} results found',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Custom compass at the bottom
          Positioned(
            bottom: 80,
            right: 16,
            child: Transform.rotate(
              angle: -_mapBearing * (pi / 180),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          // My location button
          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _centerOnUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
