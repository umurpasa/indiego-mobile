import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  final String _baseUrl = 'https://localhost:9001';

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl/api/Account/authenticate/mobile');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['jwToken'] ?? responseData['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token.toString());
          final rolesRaw = responseData['roles'];
          final isSeller = rolesRaw is List
              ? rolesRaw.any((r) => r.toString().toLowerCase() == 'seller')
              : rolesRaw?.toString().toLowerCase() == 'seller';
          await prefs.setBool('is_seller', isSeller);
          // Save user info for use in drawer / other screens
          await prefs.setString(
              'user_first_name', (responseData['firstName'] ?? '').toString());
          await prefs.setString(
              'user_last_name', (responseData['lastName'] ?? '').toString());
          await prefs.setString(
              'user_email', (responseData['email'] ?? '').toString());
          await prefs.setString(
              'user_username', (responseData['userName'] ?? '').toString());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Giriş Başarılı!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Token bulunamadı: $responseData'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
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

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A16);
    const primaryPurple = Color(0xFFA088E4);
    const inputBgColor = Color(0xFF1A1A2E);
    const borderColor = Color(0xFF2A2A4E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Space background image
          // Vercel projesindeki space-bg.webp dosyasını
          // Flutter projesinde assets/images/ klasörüne kopyala
          // ve pubspec.yaml'a ekle. O zamana kadar gradient arka plan gösterilir.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/space-bg.webp'),
                fit: BoxFit.cover,
                onError: _ignoreImageError,
              ),
            ),
          ),
          // Dark overlay
          Container(color: bgColor.withOpacity(0.88)),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/icon-128.png',
                          width: 64,
                          height: 64,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.videogame_asset,
                                  size: 64, color: primaryPurple),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'INDIEGO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Email Field
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 14),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primaryPurple, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 14),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primaryPurple, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showInfo(
                            'To reset your password, please visit indiego.com on a desktop browser.'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: primaryPurple, fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In Button
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
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Sign up',
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

// AssetImage hata durumunda sessizce geç
void _ignoreImageError(Object error, StackTrace? stackTrace) {}

