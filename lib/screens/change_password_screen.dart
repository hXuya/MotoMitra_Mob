import 'package:flutter/material.dart';
import 'package:moto_mitra/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (response['status'] == 200) {
        _showSnackBar("Password changed successfully");
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pop(context);
      } else {
        _showSnackBar(response['msg'] ?? "Failed to change password");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.lock_reset,
                    size: 100,
                    color: const Color(0xFFFF9900),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Update Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9900),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please enter your current password and a new password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 30),
                _buildInput(
                  'Current Password',
                  Icons.lock_outline,
                  _oldPasswordController,
                  obscure: _obscureOldPassword,
                  toggleIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFE58A00),
                    ),
                    onPressed: () => setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    }),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  'New Password',
                  Icons.lock_outline,
                  _newPasswordController,
                  obscure: _obscureNewPassword,
                  toggleIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFE58A00),
                    ),
                    onPressed: () => setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    }),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  'Confirm New Password',
                  Icons.lock_outline,
                  _confirmPasswordController,
                  obscure: _obscureConfirmPassword,
                  toggleIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFE58A00),
                    ),
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF9900),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA800),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    Widget? toggleIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFCEFE8),
        prefixIcon: Icon(icon, color: const Color(0xFFE58A00)),
        suffixIcon: toggleIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8C5AE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8C5AE)),
        ),
      ),
    );
  }
}
