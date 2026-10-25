import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/inventory/screens/dashboard_screen.dart';
import 'package:smartfix_mobile/features/profile/screens/feedback_screen.dart';
import 'package:smartfix_mobile/features/profile/screens/profile_screen.dart';
import 'package:smartfix_mobile/features/repairs/screens/repair_tracking_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/tools_hub_screen.dart';

/// Layout utama (Main Navigation Container) aplikasi SmartFix Mobile.
/// Menyediakan BottomNavigationBar (Material 3) untuk navigasi 5 menu utama:
/// 1. Dasbor: Manajemen dan pencarian katalog inventaris suku cadang
/// 2. Alat: Hub utilitas teknisi (AI Diagnostik, Blockchain SHA-256, Konversi Waktu/Kurs, Peta LBS, Mini Game Gyro)
/// 3. Perbaikan: Pelacakan tiket servis pelanggan dan update status pengerjaan
/// 4. Ulasan: Formulir evaluasi dan Saran & Kesan mata kuliah PAM
/// 5. Profil: Informasi akun teknisi, foto profil dinamis, dan tombol logout aman
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Indeks tab yang sedang aktif dipilih pengguna
  int _currentIndex = 0;

  // Daftar layar yang dihubungkan ke Bottom Navigation Bar
  final List<Widget> _screens = const [
    DashboardScreen(),
    ToolsHubScreen(),
    RepairTrackingScreen(),
    FeedbackScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mempertahankan state halaman agar form/scroll position tidak reset saat berpindah tab
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dasbor',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Alat',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Perbaikan',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Ulasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
