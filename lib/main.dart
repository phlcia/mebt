import 'package:flutter/material.dart';
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
      title: 'Flutter Demo',
      theme: ThemeData(
        // You can try changing the seedColor for a different theme.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Set the home to the LoadingScreen instead of directly to MapPage
      home: const LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    // Simulate a delay for loading resources (e.g., data fetch, initialization, etc.)
    await Future.delayed(const Duration(seconds: 3));
    // Navigate to MapPage after the delay
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MapPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the splash image as the loading screen
      body: Center(
        child: Image.asset('./assets/splash.jpg'),
      ),
    );
  }
}