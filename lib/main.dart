import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/api_service.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';
import 'package:smartfix_mobile/features/auth/screens/login_screen.dart';
import 'package:smartfix_mobile/main_layout.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local notifications system
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();
  await notificationHelper.requestPermissions();

  // Check SharedPreferences on startup for an existing authentication token
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString(ApiService.tokenKey);
  final bool isLoggedIn = token != null && token.trim().isNotEmpty;

  if (isLoggedIn) {
    // Restore session state for ApiService and AuthHelper
    final String? username = prefs.getString('user_name');
    final authHelper = AuthHelper();
    authHelper.restoreSession(
      token: token,
      username: username ?? 'Technician',
    );
  }

  runApp(SmartFixApp(isLoggedIn: isLoggedIn));
}

class SmartFixApp extends StatelessWidget {
  final bool isLoggedIn;

  const SmartFixApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFix Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // Modern Teal / Cyan repair theme
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
