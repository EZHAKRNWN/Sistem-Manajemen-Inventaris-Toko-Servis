// ============================================================================
// FITUR: PENGATURAN PROFIL TEKNISI & STATISTIK KERJA (PROFILE SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Personalisasi Akun: Penggantian foto profil teknisi dari galeri perangkat (ImagePicker)
//    disimpan secara persisten ke SharedPreferences lokal.
// 2. Metrik Kinerja Teknisi (KPI Stats): Menampilkan statistik real-time dari backend Laravel
//    (Total Servis Selesai, Suku Cadang Terverifikasi, dan Tiket Menunggu).
// 3. Konfigurasi Preferensi: Tombol toggle aktivasi Push Notification dan Login Biometrik Sidik Jari.
// 4. Integrasi Menu Akademik & Alat Tambahan: Navigasi ke Layar Saran & Kesan PAM,
//    Konverter Kurs & Waktu Dunia, serta Lembar Kriteria Tugas Akhir PAM.
// 5. Manajemen Kredensial: Fitur logout aman yang menghapus token Sanctum dari FlutterSecureStorage.
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/api_service.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/features/auth/screens/login_screen.dart';
import 'package:smartfix_mobile/features/profile/screens/feedback_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/currency_time_converter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthHelper _authHelper = AuthHelper();
  final ApiService _api = ApiService();

  // Preferensi toggle pengaturan notifikasi dan biometrik
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;

  // Statistik kinerja teknisi dari API backend Laravel
  int _completedRepairs = 0;
  int _verifiedParts = 0;
  int _pendingTickets = 0;
  bool _isLoadingStats = true;

  // Path avatar custom teknisi dari penyimpanan lokal
  String? _customAvatarPath;
  static const String _defaultAvatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300';

  @override
  void initState() {
    super.initState();
    // 1. Memuat statistik ringkasan tiket dan suku cadang dari API
    _loadTechnicianStats();
    // 2. Memuat foto avatar lokal yang tersimpan di memori perangkat
    _loadCustomAvatar();
  }

  /// FITUR: Membaca path file avatar kustom dari SharedPreferences
  Future<void> _loadCustomAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('custom_avatar_path');
    if (path != null && mounted) {
      setState(() => _customAvatarPath = path);
    }
  }

  /// FITUR: Mengunggah/Mengganti Foto Profil dari Galeri Handphone (ImagePicker)
  Future<void> _pickAvatarImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_avatar_path', picked.path);
        if (mounted) {
          setState(() => _customAvatarPath = picked.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  /// FITUR: Sinkronisasi Statistik Teknisi dari REST API Laravel
  Future<void> _loadTechnicianStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _api.getTechnicianStats();
      if (!mounted) return;
      int parseVal(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString()) ?? 0;
      }

      setState(() {
        _completedRepairs = parseVal(stats['completed_repairs']);
        _verifiedParts = parseVal(stats['verified_parts']);
        _pendingTickets = parseVal(stats['pending_tickets']);
        _isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi SmartFix Mobile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authHelper.clearSession();
              await ApiService.clearToken();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    bool isPhysical = ApiService.isPhysicalDevice;
    final ipController = TextEditingController(text: ApiService.localNetworkIp);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.dns_rounded, color: Color(0xFF14B8A6)),
                SizedBox(width: 8),
                Text('Koneksi Server API', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih target server backend Laravel:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Emulator'),
                          icon: Icon(Icons.android),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('HP Fisik'),
                          icon: Icon(Icons.smartphone),
                        ),
                      ],
                      selected: {isPhysical},
                      onSelectionChanged: (newSelection) {
                        setDialogState(() => isPhysical = newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isPhysical) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address Laptop/Server',
                        hintText: 'mis. 192.168.100.12',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Target URL: http://${isPhysical ? ipController.text.trim() : '10.0.2.2'}:${ApiService.port}/api',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  ApiService.setIsPhysicalDevice(isPhysical);
                  if (isPhysical && ipController.text.trim().isNotEmpty) {
                    ApiService.setLocalNetworkIp(ipController.text.trim());
                  }
                  Navigator.of(ctx).pop();
                  setState(() {});
                  _loadTechnicianStats();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('URL API diubah ke: ${ApiService.baseUrl}'),
                    ),
                  );
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = _authHelper.currentUsername ?? 'Teknisi Senior';

    ImageProvider profileImage;
    if (_customAvatarPath != null && File(_customAvatarPath!).existsSync()) {
      profileImage = FileImage(File(_customAvatarPath!));
    } else {
      profileImage = const NetworkImage(_defaultAvatarUrl);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Statistik',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTechnicianStats,
          ),
          IconButton(
            tooltip: 'Keluar dari Sesi',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTechnicianStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage: profileImage,
                              child: Container(),
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickAvatarImage,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahasiswa PAM / Teknisi Sistem • SmartFix Mobile',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Sesi Aktif Terverifikasi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _pickAvatarImage,
                            child: Text(
                              'Ubah Foto',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _buildStatItem(
                    'Perbaikan Selesai',
                    _isLoadingStats ? '...' : '$_completedRepairs',
                    Icons.build_circle_outlined,
                    const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  _buildStatItem(
                    'Part Terverifikasi',
                    _isLoadingStats ? '...' : '$_verifiedParts',
                    Icons.verified_outlined,
                    const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  _buildStatItem(
                    'Tiket Tertunda',
                    _isLoadingStats ? '...' : '$_pendingTickets',
                    Icons.hourglass_top_outlined,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rate_review_rounded,
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                      title: const Text(
                        'Saran & Kesan Mata Kuliah PAM',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Kesan perkuliahan dan evaluasi Pemrograman Aplikasi Mobile',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.amber,
                        ),
                      ),
                      title: const Text(
                        'Zona Waktu & Jam Operasional',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Waktu kerja suplier global (WIB, WITA, WIT, London, Shenzhen, Tokyo, NY)',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CurrencyTimeConverterScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.dns_rounded,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  title: const Text(
                    'Koneksi Server REST API',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    ApiService.isPhysicalDevice
                        ? 'Smartphone Fisik (${ApiService.localNetworkIp}:${ApiService.port})'
                        : 'Android Emulator (10.0.2.2:${ApiService.port})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.tune_rounded),
                  onTap: _showServerConfigDialog,
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifikasi Push'),
                      subtitle: const Text(
                        'Peringatan stok menipis dan tiket perbaikan',
                      ),
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      value: _notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Autentikasi Biometrik'),
                      subtitle: const Text(
                        'Gunakan Sidik Jari atau Face ID untuk masuk cepat',
                      ),
                      secondary: const Icon(Icons.fingerprint),
                      value: _biometricEnabled,
                      onChanged: (val) =>
                          setState(() => _biometricEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              FilledButton.tonalIcon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar dari Sesi (Logout)',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
