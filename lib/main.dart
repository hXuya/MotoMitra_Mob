import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
// import 'screens/signin_screen.dart';
import 'screens/main_screen.dart';
// import 'screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Set initial route to splash screen
      routes: {
        '/': (context) => const SplashScreen(), // Splash Screen route
        // '/signin': (context) => const SignInScreen(), // Sign In route
        // '/signup': (context) => const SignUpScreen(), // Sign Up route
        '/home': (context) => HomeScreen(), // Home Screen route
      },
    );
  }
}
