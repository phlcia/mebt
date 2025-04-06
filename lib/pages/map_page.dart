import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hi/consts.dart';
import 'package:location/location.dart' hide LocationAccuracy;

import 'package:geolocator/geolocator.dart';





class MapPage extends StatefulWidget {
const MapPage({super.key});




@override
State<MapPage> createState() => _MapPageState();
}




class _MapPageState extends State<MapPage> {
Location _locationController = new Location();




final Completer<GoogleMapController> _mapController =
    Completer<GoogleMapController>();




static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
LatLng? _currentP;




Map<PolylineId, Polyline> polylines = {};




@override
void initState() {
  super.initState();
  getLocationUpdates().then(
    (_) => {
      getPolylinePoints().then(
        (coordinates) => {generatePolyLineFromPoints(coordinates)},
      ),
    },
  );
}




@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) =>
            _mapController.complete(controller),
        // Use _currentP if available; otherwise default to _pGooglePlex.
        initialCameraPosition: CameraPosition(
          target: _currentP ?? _pGooglePlex,
          zoom: 13,
        ),
        markers: {
          // Add the current location marker only if _currentP is not null.
          if (_currentP != null)
            Marker(
              markerId: MarkerId("_currentLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: _currentP!,
            ),
          Marker(
            markerId: MarkerId("_sourceLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _pGooglePlex,
          ),
          Marker(
            markerId: MarkerId("_destinationLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _pApplePark,
          ),
        },
        polylines: Set<Polyline>.of(polylines.values),
      ),
    );
  }








Future<void> _cameraToPosition(LatLng pos) async {
  final GoogleMapController controller = await _mapController.future;
  CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 13);
  await controller.animateCamera(
    CameraUpdate.newCameraPosition(_newCameraPosition),
  );
}




Future<void> getLocationUpdates() async {
  bool serviceEnabled;
  PermissionStatus permissionGranted;




  serviceEnabled = await _locationController.serviceEnabled();
  if (serviceEnabled) {
    serviceEnabled = await _locationController.requestService();
  } else {
    return;
  }




  permissionGranted = await _locationController.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await _locationController.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }
  }




  _locationController.onLocationChanged.listen((
    LocationData currentLocation,
  ) {
    if (currentLocation.latitude != null &&
        currentLocation.longitude != null) {
      setState(() {
        _currentP = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        _cameraToPosition(_currentP!);
      });
    }
  });
}




Future<List<LatLng>> getPolylinePoints() async {
  List<LatLng> polylineCoordinates = [];




  PolylinePoints polylinePoints = PolylinePoints();




  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    googleApiKey: GOOGLE_MAPS_API_KEY,
    request: PolylineRequest(
      origin: PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
      destination: PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
      mode: TravelMode.driving,
    ),
  );




  if (result.points.isNotEmpty) {
    for (var point in result.points) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
  } else {
    if (kDebugMode) {
      print(result.errorMessage);
    }
  }
  return polylineCoordinates;
}




void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
  PolylineId id = PolylineId("poly");
  Polyline polyline = Polyline(
    polylineId: id,
    color: Colors.black,
    points: polylineCoordinates,
    width: 8,
  );
  setState(() {
    polylines[id] = polyline;
  });
}
/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
 bool serviceEnabled;
 LocationPermission permission;


 // Test if location services are enabled.
 serviceEnabled = await Geolocator.isLocationServiceEnabled();
 if (!serviceEnabled) {
   // Location services are not enabled don't continue
   // accessing the position and request users of the
   // App to enable the location services.
   return Future.error('Location services are disabled.');
 }


 permission = await Geolocator.checkPermission();
 if (permission == LocationPermission.denied) {
   permission = await Geolocator.requestPermission();
   if (permission == LocationPermission.denied) {
     // Permissions are denied, next time you could try
     // requesting permissions again (this is also where
     // Android's shouldShowRequestPermissionRationale
     // returned true. According to Android guidelines
     // your App should show an explanatory UI now.
     return Future.error('Location permissions are denied');
   }
 }
  if (permission == LocationPermission.deniedForever) {
   // Permissions are denied forever, handle appropriately.
   return Future.error(
     'Location permissions are permanently denied, we cannot request permissions.');
 }


 // When we reach here, permissions are granted and we can
 // continue accessing the position of the device.
 return await Geolocator.getCurrentPosition();
}

final LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 100,
);

// to set up position stuff 
Future<void> fetchCurrentGeoposition() async {
	try 
	{
		Position currentposition = await Geolocator.getCurrentPosition(
    locationSettings: locationSettings,
);

//setState(() {
	//_latitude = ‘Latitude: ${currentposition.latitude}’;
	//_longitude = ‘Longitude: ${currentposition.longitude}’;

// });
} catch (error) 
{
	print('Error: $error');

}



}
}
