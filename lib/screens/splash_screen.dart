import 'dart:async';
import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromRGBO(255, 246, 241, 1),
        child: Stack(
          children: [
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
            Center(
              child: Image.asset(
                'assets/icons/logo.png',
                width: 250,
                height: 250,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
