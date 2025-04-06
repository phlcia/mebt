// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'map_page.dart'; // Import the map page to navigate to it

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EBT Locator Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapPage()),
            );
          },
          child: Text('Login'),
        ),
      ),
    );
  }
}
