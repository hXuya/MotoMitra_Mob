import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final Map<String, String> _userData = {
    "username": "Ayush Shrestha",
    "email": "ayush04061@gmail.com",
    "phone": "9832983928",
  };

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA800),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE8C5AE),
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: const Color(0xFFE58A00),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // User Info (Static Data)
            _infoTile('Name', _userData['username']!),
            _infoTile('Email', _userData['email']!),
            _infoTile('Phone', _userData['phone']!),

            const SizedBox(height: 40),

            // Logout Button
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E00),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8C5AE)),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE58A00),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
