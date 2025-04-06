import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String baseUrl =
      dotenv.env['baseurl'] ?? 'http://localhost:8000';

  // Login user
  static Future<Map<String, dynamic>> loginUser(
      String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        return {
          'status': 200,
          'message': data['msg'],
          'token': data['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': response.statusCode,
          'message': errorData['msg'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      print('Error: $e');
      return {'status': 500, 'message': 'Server error'};
    }
  }

  // Fetch user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'status': 401, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 200,
          'message': data['msg'],
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': response.statusCode,
          'message': errorData['msg'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      print('Error: $e');
      return {'status': 500, 'message': 'Server error'};
    }
  }

  // Store token
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // Logout
  static Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}
