import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/auth/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Tunggu 3 detik lalu pindah ke Login
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.assignment,
              size: 100,
              color: const Color(0xFF4F46E5),
            ),
            SizedBox(height: 20),
            Text(
              'Field Survey',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Aplikasi Mobile Berbasis Flutter',
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 40),

            // Loading
            CircularProgressIndicator(),

            SizedBox(height: 15),

            Text(
              "Loading...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}