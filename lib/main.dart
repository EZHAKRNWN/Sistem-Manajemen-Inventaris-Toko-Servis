import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/api_service.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/globals.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';
import 'package:smartfix_mobile/features/auth/screens/login_screen.dart';
import 'package:smartfix_mobile/main_layout.dart';

/// Titik masuk utama (entry point) aplikasi SmartFix Mobile.
/// Fungsi main mempersiapkan inisialisasi plugin offline, pemeriksaan sesi login tersimpan,
/// dan menentukan apakah user langsung diarahkan ke MainLayout (Dasbor) atau LoginScreen.
void main() async {
  // 1. Memastikan binding framework Flutter telah siap sebelum mengeksekusi asynchronous code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi sistem notifikasi lokal (tanpa dependensi Firebase) dan meminta izin notifikasi
  final notificationHelper = NotificationHelper();
  await notificationHelper.init();
  await notificationHelper.requestPermissions();

  // 3. Memeriksa keberadaan token autentikasi (FlutterSecureStorage & SharedPreferences)
  // Fitur ini memungkinkan auto-login saat aplikasi dibuka kembali
  final prefs = await SharedPreferences.getInstance();
  String? token = await ApiService.getToken();
  token ??= prefs.getString(ApiService.tokenKey);
  final bool isLoggedIn = token != null && token.trim().isNotEmpty;

  // 4. Jika sesi login ditemukan, pulihkan session state dan data profil teknisi ke memori
  if (isLoggedIn) {
    final String? username = prefs.getString('user_name');
    final authHelper = AuthHelper();
    authHelper.restoreSession(token: token, username: username ?? 'Teknisi');
  }

  // 5. Menjalankan widget root aplikasi dengan status login awal
  runApp(SmartFixApp(isLoggedIn: isLoggedIn));
}

/// Root Widget aplikasi SmartFix Mobile.
/// Mengonfigurasi tema industrial-dark (Material 3), routing global, dan halaman awal.
class SmartFixApp extends StatelessWidget {
  final bool isLoggedIn;

  const SmartFixApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    // Definisi tema gelap konsisten (Industrial-Tech: Teal & Dark Charcoal)
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      canvasColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF14B8A6),
        brightness: Brightness.dark,
        surface: const Color(0xFF262626),
        onSurface: const Color(0xFFF5F5F5),
        primary: const Color(0xFF14B8A6),
        secondary: const Color(0xFF0F766E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF262626),
        foregroundColor: Color(0xFFF5F5F5),
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF262626),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF383838)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF262626),
        indicatorColor: const Color(0xFF0F766E).withValues(alpha: 0.6),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF14B8A6));
          }
          return const IconThemeData(color: Color(0xFFA3A3A3));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF14B8A6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            );
          }
          return const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12);
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF262626),
        titleTextStyle: TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
      ),
      dividerColor: const Color(0xFF383838),
    );

    return MaterialApp(
      // Global Navigator Key untuk navigasi tanpa BuildContext (misal saat interceptor 401 redirect ke Login)
      navigatorKey: globalNavigatorKey,
      title: 'SmartFix Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: darkTheme,
      darkTheme: darkTheme,
      // Jika sudah login arahkan langsung ke MainLayout (Dasbor), jika belum arahkan ke LoginScreen
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
