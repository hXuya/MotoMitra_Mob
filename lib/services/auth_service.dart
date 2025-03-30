// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class AuthService {
//   static const String baseUrl =
//       'http://192.168.1.77:8000/api/user'; // Update if needed

//   static Future<Map<String, dynamic>> verifyOtp(
//       String email, String otp) async {
//     final url = Uri.parse('$baseUrl/verify');
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'otp': otp}),
//     );192.168.1.77

//     final data = jsonDecode(response.body);
//     return {
//       'status': response.statusCode,
//       'message': data['msg'],
//     };
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'http://100.64.204.28:8000/api/user'; // Update if needed

  // Login User
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);
    return {
      'status': response.statusCode,
      'message': data['msg'],
      'token': data['token'],
      'user': data['data'],
      'role': data['role']
    };
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final url = Uri.parse('$baseUrl/verify');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);
    return {
      'status': response.statusCode,
      'message': data['msg'],
    };
  }

  /// 👤 Fetch Logged-In User
  static Future<Map<String, dynamic>> fetchLoggedInUser(String token) async {
    final url = Uri.parse('$baseUrl/loggedInUser');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    return {
      'status': response.statusCode,
      'message': data['msg'],
      'user': data['data'],
    };
  }

  // Store JWT Token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get JWT Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Logout and clear token
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
