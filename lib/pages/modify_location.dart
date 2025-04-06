import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:geolocator/geolocator.dart';

class ModifyLocation extends StatefulWidget {
  const ModifyLocation({super.key});

  @override
  State<ModifyLocation> createState() => _ModifyLocationState();
}

class _ModifyLocationState extends State<ModifyLocation> {

  String _latitude = 'Latitude';
  String _longitude = 'Longitude';

  Future<void> fetchCurrentGeopostion() async 
  {
    try 
    {
      final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
      );
      
      Position currentposition = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      
      setState(() {
        _latitude = 'Latitude: ${currentposition.latitude}';
        _longitude = 'Longitude: ${currentposition.longitude}';
      });
    } catch (error) 
    {
      // ignore: avoid_print
      print('Error: $error');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoLocator'),
        centerTitle: true,
      ),
      // body: Container(
      //   decoration: BoxDecoration(
      //     gradient: LinearGradient(colors: Colors.blue))
      // ),
    );
  }
}