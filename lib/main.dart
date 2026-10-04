import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';
import 'package:smartfix_mobile/main_layout.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local notifications system
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();
  await notificationHelper.requestPermissions();

  runApp(const SmartFixApp());
}

class SmartFixApp extends StatelessWidget {
  const SmartFixApp({super.key});

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
      home: const MainLayout(),
    );
  }
}
