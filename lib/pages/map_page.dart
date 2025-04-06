import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> markers = {};

  // Initial camera position centered on the US.
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(39.8283, -98.5795),
    zoom: 4,
  );

  double _mapBearing = 0.0;

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _mapBearing = position.bearing;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: markers,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: false,
            myLocationButtonEnabled: true,
          ),
          // Sticky, rounded search bar at the top
          Positioned(
            top: MediaQuery.of(context).padding.top + 14, // Adjust for safe area on iOS if needed
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
                  )
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for a store',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // Implement your search filtering logic here
                },
              ),
            ),
          ),
        // Custom Compass placed above the default location button
          Positioned(
            bottom: 80, // Adjust based on where the location button is
            right: 16,
            child: Transform.rotate(
              angle: (_mapBearing * (3.14159265 / 180) * -1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white70,
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
        ],
      ),
    );
  }
}