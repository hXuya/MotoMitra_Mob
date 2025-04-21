import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'signin_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final Function(String token)? onVerificationSuccess;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.onVerificationSuccess,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  final String baseUrl = dotenv.env['baseurl'] ?? 'http://localhost:8000';

  Future<void> _verifyOTP() async {
    String otp = _otpController.text;
    if (otp.length != 6) {
      _showMessage('Please enter a complete 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!(data['token']);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
      } else {
        _showMessage(data['msg'] ?? 'Verification failed');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final data = jsonDecode(response.body);
      _showMessage(data['msg'] ?? 'OTP resent successfully');
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF9900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9900),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            _buildOtpInput(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA800),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Verify',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? "),
                GestureDetector(
                  onTap: _isLoading ? null : _resendOTP,
                  child: Text(
                    "Resend",
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : const Color(0xFFFF5E00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFCEFE8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8C5AE)),
              ),
              alignment: Alignment.center,
              child: Text(
                _otpController.text.length > index
                    ? _otpController.text[index]
                    : '',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            style: const TextStyle(color: Colors.transparent),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => setState(() {}),
            showCursor: false,
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _otpFocusNode.requestFocus(),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
