import 'package:flutter/material.dart';
import 'package:hi/GetLocation/modify_location.dart';
import 'package:hi/pages/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeoLocator',
      theme: ThemeData(
        // Change the seedColor for a different theme.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ModifyLocation(),
    );
  }
}