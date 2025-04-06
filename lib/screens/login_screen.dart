import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MapPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleLogin(context),
          child: const Text('Login'),
        ),
      ),
    );
  }
}
