import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moto_mitra/screens/change_password_screen.dart';
import 'package:moto_mitra/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'signin_screen.dart';
import 'main_screen.dart';
import 'profile_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String userName;
  final String? userImage;

  const AccountSettingsScreen({
    super.key,
    required this.userName,
    this.userImage,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late String userName;
  String? userImage;
  final String baseUrl = dotenv.env['baseurl'] ?? 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    userImage = widget.userImage;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await AuthService.getProfile();
      if (response['status'] == 200 && mounted) {
        setState(() {
          userName = response['data']['name'];
          userImage = response['data']['imageUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load profile: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    try {
      if (!mounted) return;

      _showSnackBar("Logged out successfully");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error logging out: ${e.toString()}");
    }
  }

  Future<void> _callEmergencySupport() async {
    _showEmergencyDialog();
  }

  void _showEmergencyDialog() {
    const String emergencyNumber = '+9779765313984';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF5F2),
          title: const Text(
            'Emergency Support',
            style: TextStyle(color: Color(0xFFFF9900)),
          ),
          content: Text('Please call our emergency number: $emergencyNumber'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchCall(emergencyNumber);
              },
              child: const Text(
                'Call Now',
                style: TextStyle(color: Color(0xFFFF5E00)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchCall(String number) async {
    try {
      final Uri uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final String telUrl = 'tel:$number';
        if (await canLaunch(telUrl)) {
          await launch(telUrl);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Could not initiate call");
    }
  }

  Widget _buildSettingOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEFE8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8C5AE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE58A00), size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFE58A00),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF9900)),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFFCEFE8),
                backgroundImage:
                    userImage != null ? NetworkImage(userImage!) : null,
                child: userImage == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFFE58A00),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 40),
              _buildSettingOption(
                'Profile',
                Icons.person_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingOption(
                'My Vehicle',
                Icons.directions_car_outlined,
                () => _navigateToSection('vehicle'),
              ),
              const SizedBox(height: 16),
              _buildSettingOption(
                'Change Password',
                Icons.lock_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingOption(
                'Emergency Support',
                Icons.emergency_outlined,
                _callEmergencySupport,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _showLogoutConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA800),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF5F2),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Color(0xFFFF9900)),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFFF5E00)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSection(String section) {
    _showSnackBar("Navigating to $section settings");
  }
}
