import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final String _baseUrl = 'https://localhost:9001';

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler eşleşmiyor!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl/api/Account/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'userName': _userNameController.text.trim(),
          'password': _passwordController.text.trim(),
          'confirmPassword': _confirmPasswordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt Başarılı! Giriş yapabilirsiniz.'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata (${response.statusCode}):\n${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFA088E4),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool? showPassword,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !(showPassword ?? false),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA088E4), width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword == true
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A16);
    const primaryPurple = Color(0xFFA088E4);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Space background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/space-bg.webp'),
                fit: BoxFit.cover,
                onError: _ignoreImageError,
              ),
            ),
          ),
          Container(color: bgColor.withOpacity(0.88)),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo + Title
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/icon-128.png',
                          width: 52,
                          height: 52,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.videogame_asset,
                                  size: 52, color: primaryPurple),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'INDIEGO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // First Name & Last Name row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('First Name'),
                              _buildTextField(
                                hint: 'First name',
                                controller: _firstNameController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Last Name'),
                              _buildTextField(
                                hint: 'Last name',
                                controller: _lastNameController,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Email'),
                    _buildTextField(
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Username'),
                    _buildTextField(
                      hint: 'Choose a username',
                      controller: _userNameController,
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Password'),
                    _buildTextField(
                      hint: 'Create a password',
                      controller: _passwordController,
                      isPassword: true,
                      showPassword: _showPassword,
                      onTogglePassword: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Confirm Password'),
                    _buildTextField(
                      hint: 'Repeat your password',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      showPassword: _showConfirmPassword,
                      onTogglePassword: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                    ),

                    const SizedBox(height: 28),

                    // Sign Up Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryPurple, Color(0xFF6A5ACD)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already registered? ',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: primaryPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _ignoreImageError(Object error, StackTrace? stackTrace) {}
