import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String baseUrl =
      dotenv.env['baseurl'] ?? 'http://localhost:8000';

  static String? formatProfileImageUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return null;

    if (profileImage.startsWith('http://') ||
        profileImage.startsWith('https://')) {
      return profileImage;
    }

    String cleanPath = profileImage;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (cleanPath.startsWith('images/')) {
      return '$baseUrl/$cleanPath';
    } else {
      return '$baseUrl/images/$cleanPath';
    }
  }

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
      return {'status': 500, 'message': 'Server error'};
    }
  }

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
      return {'status': 500, 'message': 'Server error'};
    }
  }

  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'status': 401, 'msg': 'Unauthorized: Token not found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'status': response.statusCode,
        'msg': data['msg'] ?? 'Unknown response',
      };
    } catch (e) {
      return {'status': 500, 'msg': 'Server error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, String> data) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'status': 401, 'message': 'No token found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/updateProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'status': 200,
          'message': responseData['msg'],
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': response.statusCode,
          'message': errorData['msg'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      return {'status': 500, 'message': 'Server error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfileWithImage(
    Map<String, String> data,
    String imagePath,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'status': 401, 'message': 'No token found'};
      }

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/user/updateProfile'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      data.forEach((key, value) {
        request.fields[key] = value;
      });

      if (imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('profileImage', imagePath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'status': 200,
          'message': responseData['msg'],
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': response.statusCode,
          'message': errorData['msg'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      return {'status': 500, 'message': 'Server error: ${e.toString()}'};
    }
  }
}
