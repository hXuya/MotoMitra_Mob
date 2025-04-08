import 'package:flutter/material.dart';
import 'package:moto_mitra/screens/change_password_screen.dart';
import 'package:moto_mitra/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'signin_screen.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'my_vehicle_screen.dart';

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
  bool _isLoading = false;
  String _imageTimestamp = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    userImage = widget.userImage;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthService.getProfile();

      if (response['status'] == 200 && mounted) {
        final userData = response['data'];
        setState(() {
          userName = userData['username'] ?? '';
          userImage =
              AuthService.formatProfileImageUrl(userData['profileImage']);
          _imageTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      await AuthService.logout();
      if (!mounted) return;

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

  void _callEmergencySupport() {
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
      final String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri uri = Uri.parse('tel:$cleanNumber');

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!launched && mounted) {
        _showSnackBar(
            "Failed to open dialer. Please call $cleanNumber manually.");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Could not open phone dialer: ${e.toString()}");
      }
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9900)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEFE8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE8C5AE),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildProfileImage(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9900),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSettingOption(
                      'Profile',
                      Icons.person_outline,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ).then((_) => _fetchUserProfile());
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSettingOption(
                      'My Vehicle',
                      Icons.directions_car_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyVehicleScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSettingOption(
                      'Change Password',
                      Icons.lock_outline,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChangePasswordScreen()),
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

  Widget _buildProfileImage() {
    if (userImage != null && userImage!.isNotEmpty) {
      return Image.network(
        "$userImage?t=$_imageTimestamp",
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFFFF9900),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 60,
            color: Color(0xFFE58A00),
          );
        },
      );
    } else {
      return const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFFE58A00),
      );
    }
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
}
