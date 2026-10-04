import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';
import 'package:smartfix_mobile/features/auth/widgets/biometric_btn.dart';
import 'package:smartfix_mobile/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'technician_01');
  final _passwordController = TextEditingController(text: 'repairpass123');
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthHelper _authHelper = AuthHelper();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Generates a mock JWT/Bearer session token
  String _generateSessionToken(String username) {
    final randomPart = Random().nextInt(999999).toString().padLeft(6, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'smartfix_${username}_${timestamp}_$randomPart';
  }

  void _onLoginSuccess(String token, String username) {
    _authHelper.setSession(token: token, username: username);

    // Trigger local push notification on successful login
    NotificationHelper().showNotification(
      id: 101,
      title: 'Welcome Back, $username!',
      body: 'You are securely logged into SmartFix Mobile.',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  }

  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate API delay

    final username = _usernameController.text.trim();
    final token = _generateSessionToken(username);

    setState(() => _isLoading = false);
    _onLoginSuccess(token, username);
  }

  void _handleBiometricSuccess() {
    final username = _usernameController.text.isNotEmpty
        ? _usernameController.text.trim()
        : 'tech_biometric_user';
    final token = _generateSessionToken(username);
    _onLoginSuccess(token, username);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.build_circle,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SmartFix Mobile',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Smartphone Repair & Inventory System',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Technician ID / Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'Please enter your username' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.length < 4) ? 'Password too short' : null,
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  FilledButton(
                    onPressed: _isLoading ? null : _handlePasswordLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Biometric Button
                  BiometricBtn(
                    onSuccess: _handleBiometricSuccess,
                    onError: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
