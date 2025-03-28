import 'dart:async';
import 'package:flutter/material.dart';
import 'signin_screen.dart'; // ✅ Import the correct renamed SignInScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Set timer to navigate after 2 seconds
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const SignInScreen(), // ✅ Navigate to SignInScreen
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 246, 241, 1), // Soft background
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top left circle
            Positioned(
              top: -200,
              left: -90,
              child: Container(
                width: 350,
                height: 350,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFBB99),
                ),
              ),
            ),
            // Top right circle
            Positioned(
              top: -240,
              right: -80,
              child: Container(
                width: 370,
                height: 370,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDC9105),
                ),
              ),
            ),
            // Bottom left circle
            Positioned(
              bottom: -200,
              left: -90,
              child: Container(
                width: 350,
                height: 350,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFBB99),
                ),
              ),
            ),
            // Bottom right circle
            Positioned(
              bottom: -240,
              right: -80,
              child: Container(
                width: 370,
                height: 370,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDC9105),
                ),
              ),
            ),
            // Logo center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/logo.png',
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
