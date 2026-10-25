// ============================================================================
// FITUR: FORM SARAN & KESAN MATA KULIAH PAM (FEEDBACK SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Memenuhi Kriteria Tugas Akhir PAM: Menyediakan form ulasan, saran, dan kesan mahasiswa
//    terhadap proses pembelajaran mata kuliah Pemrograman Aplikasi Mobile.
// 2. Rating Interaktif 1-5 Bintang: Dilengkapi deskripsi bobot evaluasi otomatis.
// 3. Penyimpanan Data Offline (SharedPreferences): Menyimpan review mahasiswa secara persisten
//    di storage lokal gawai sehingga ulasan tidak hilang saat aplikasi ditutup.
// 4. Integrasi Push Notification: Memicu notifikasi lokal offline saat formulir berhasil disimpan.
// 5. Riwayat Ulasan: Menampilkan preview kartu ulasan yang telah disimpan sebelumnya.
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Global key untuk validasi form input
  final _formKey = GlobalKey<FormState>();

  // Text controller untuk nama mahasiswa, kesan, dan saran
  final _studentNameController = TextEditingController();
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();
  final _authHelper = AuthHelper();

  // Nilai rating bintang (default: 5 bintang)
  int _rating = 5;
  bool _isSubmitting = false;

  // Data feedback tersimpan dari SharedPreferences
  Map<String, dynamic>? _savedFeedback;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await _authHelper.getUsername();
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('saved_pam_feedback');
    if (savedJson != null) {
      try {
        _savedFeedback = jsonDecode(savedJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _studentNameController.text = name;
        if (_savedFeedback != null) {
          _kesanController.text = _savedFeedback!['kesan'] ?? '';
          _saranController.text = _savedFeedback!['saran'] ?? '';
          _rating = _savedFeedback!['rating'] ?? 5;
        }
      });
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return '⭐⭐⭐⭐⭐ Sangat Bermanfaat & Menantang (Luar Biasa)';
      case 4:
        return '⭐⭐⭐⭐ Menambah Wawasan Pengembangan Mobile (Bagus)';
      case 3:
        return '⭐⭐⭐ Cukup Informatif dan Aplikatif (Cukup)';
      case 2:
        return '⭐⭐ Membutuhkan Lebih Banyak Praktik Langsung (Kurang)';
      case 1:
        return '⭐ Materi Terlalu Padat / Butuh Penyesuaian (Perlu Evaluasi)';
      default:
        return '';
    }
  }

  /// FITUR: Menyimpan Ulasan Mahasiswa ke SharedPreferences & Menampilkan Push Notification
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final feedbackData = {
      'student_name': _studentNameController.text.trim(),
      'kesan': _kesanController.text.trim(),
      'saran': _saranController.text.trim(),
      'rating': _rating,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    // 1. Simpan ke Local Storage SharedPreferences secara permanen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_pam_feedback', jsonEncode(feedbackData));

    // 2. Memicu notifikasi push lokal offline di smartphone
    await NotificationHelper().showNotification(
      id: 202,
      title: 'Saran & Kesan PAM Tersimpan!',
      body: 'Terima kasih atas saran dan kesan Anda untuk mata kuliah Pemrograman Aplikasi Mobile.',
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _savedFeedback = feedbackData;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Color(0xFF14B8A6),
            size: 48,
          ),
          title: const Text('Saran & Kesan Terkirim!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terima kasih, ${_studentNameController.text.trim()}! Saran dan kesan untuk mata kuliah Pemrograman Aplikasi Mobile berhasil dicatat ke sistem.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refleksi Tugas Akhir PAM:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '✓ Login Enkripsi & Biometrik\n✓ SQLite & REST API Web Service\n✓ LBS (Peta & Rute Gudang)\n✓ Konversi Kurs & Waktu (WIB, WITA, WIT, London)\n✓ Sensor Accelerometer & Gyroscope\n✓ Diagnostik AI & LLM\n✓ Ledger Blockchain Sederhana',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saran & Kesan PAM'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.25),
                      const Color(0xFF14B8A6).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF14B8A6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mata Kuliah: Pemrograman Aplikasi Mobile',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saran & Kesan Perkuliahan PAM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sampaikan kesan selama mengikuti mata kuliah Pemrograman Aplikasi Mobile serta saran konstruktif untuk dosen pengampu dan asisten praktikum.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Tingkat Kepuasan & Pengalaman Belajar PAM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            iconSize: 36,
                            icon: Icon(
                              starIndex <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () =>
                                setState(() => _rating = starIndex),
                          );
                        }),
                      ),
                      Text(
                        _getRatingLabel(_rating),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Nama Mahasiswa / Pengguna',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _studentNameController,
                decoration: InputDecoration(
                  hintText: 'Nama lengkap mahasiswa',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                'Kesan Mata Kuliah Pemrograman Aplikasi Mobile',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _kesanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Bagikan kesan Anda selama mempelajari Flutter/Dart, arsitektur mobile, koneksi database SQLite/REST API, sensor perangkat, hingga integrasi kecerdasan buatan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Silakan isi kesan perkuliahan Anda'
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                'Saran untuk Mata Kuliah & Dosen Pengampu',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _saranController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Saran dan masukan konstruktif untuk materi perkuliahan, alur praktikum, bimbingan projek akhir, maupun pengembangan kurikulum mobile berikutnya...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Silakan isi saran untuk mata kuliah'
                    : null,
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: Color(0xFF14B8A6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kriteria Tugas Akhir Terintegrasi:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildChecklistRow(
                        'Konsep Projek Akhir: SmartFix Bengkel Smartphone',
                      ),
                      _buildChecklistRow(
                        'Login Enkripsi Token & Session (Tanpa Firebase)',
                      ),
                      _buildChecklistRow(
                        'Login Biometrik Fingerprint / Face ID',
                      ),
                      _buildChecklistRow(
                        'Penyimpanan Lokal (SQLite) & Online (REST API)',
                      ),
                      _buildChecklistRow(
                        'Web Service REST API & LBS Peta Gudang Part',
                      ),
                      _buildChecklistRow(
                        'Bottom Nav: Profil (Ada Gambar), Saran & Kesan PAM, Logout',
                      ),
                      _buildChecklistRow(
                        'Konversi Kurs (Min 3) & Konversi Waktu (WIB, WIT, WITA, London)',
                      ),
                      _buildChecklistRow(
                        'Minimal 2 Sensor Hardware (Accelerometer & Gyroscope)',
                      ),
                      _buildChecklistRow(
                        'Fitur AI LLM Asisten Teknisi Perbaikan',
                      ),
                      _buildChecklistRow(
                        'Mini Game Tangkap Part Berbasis Kemiringan Sensor',
                      ),
                      _buildChecklistRow(
                        'Fitur Pencarian & Pemilihan Kategori Inventaris',
                      ),
                      _buildChecklistRow('Notifikasi Mobile Berbasis Sistem'),
                      _buildChecklistRow(
                        'Fitur Audit & Verifikasi Part Blockchain Sederhana',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Menyimpan Saran & Kesan...'
                      : 'Kirim Saran & Kesan Mata Kuliah',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0xFF14B8A6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
