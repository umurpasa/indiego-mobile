import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A16),
        elevation: 0,
        title: const Text('Account Settings',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ChangeEmailCard(),
          SizedBox(height: 16),
          _ChangePasswordCard(),
        ],
      ),
    );
  }
}

// ─── Change Email ────────────────────────────────────────────────────────────

class _ChangeEmailCard extends StatefulWidget {
  const _ChangeEmailCard();

  @override
  State<_ChangeEmailCard> createState() => _ChangeEmailCardState();
}

class _ChangeEmailCardState extends State<_ChangeEmailCard> {
  static const _baseUrl = 'https://localhost:9001';
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter a new email address.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/User/me/email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newEmail': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _emailCtrl.clear();
        _showSnack('Email updated successfully!');
      } else {
        String msg = 'Update failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) msg = body['message'];
        } catch (_) {}
        _showSnack(msg, isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      icon: Icons.mail_outline,
      title: 'Change Email',
      child: Column(
        children: [
          _InputField(
            label: 'New Email Address',
            controller: _emailCtrl,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _SubmitButton(
            label: 'Update Email',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ─── Change Password ─────────────────────────────────────────────────────────

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard();

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  static const _baseUrl = 'https://localhost:9001';
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match.', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.put(
        Uri.parse('$_baseUrl/api/v1/User/me/password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': current,
          'newPassword': newPass,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        _showSnack('Password changed successfully!');
      } else {
        String msg = 'Update failed (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) msg = body['message'];
        } catch (_) {}
        _showSnack(msg, isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF4CAF50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      icon: Icons.lock_outline,
      title: 'Change Password',
      child: Column(
        children: [
          _PasswordField(
            label: 'Current Password',
            controller: _currentCtrl,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'New Password',
            controller: _newCtrl,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label: 'Confirm New Password',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 14),
          _SubmitButton(
            label: 'Change Password',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AccountCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFA088E4), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Color(0xFF2A2A4E), height: 24),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0C3)),
        prefixIcon: Icon(icon, color: const Color(0xFFA088E4), size: 18),
        filled: true,
        fillColor: const Color(0xFF0A0A16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFA088E4)),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0C3)),
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFFA088E4), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFFB0B0C3),
            size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF0A0A16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFA088E4)),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA088E4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
