import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  double _mapBearing = 0.0;

  // Centered on the continental US
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(39.8283, -98.5795),
    zoom: 4,
  );

  @override
  void initState() {
    super.initState();
    _loadCSV();
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
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        markers: _markers,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
