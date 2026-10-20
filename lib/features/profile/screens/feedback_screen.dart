import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _authHelper = AuthHelper();

  int _rating = 5;
  String _selectedCategory = 'Kinerja & Kegunaan Aplikasi';
  String _selectedSeverity = 'Sedang (Hambatan alur kerja)';
  bool _isSubmitting = false;
  String _technicianName = 'Teknisi';

  final List<String> _categories = [
    'Kinerja & Kegunaan Aplikasi',
    'Manajemen Inventaris & Part',
    'Pemindai Barcode, QR & Blockchain',
    'Pengiriman GPS & Pelacakan Lokasi',
    'Laporan Bug / Diagnostik Crash',
    'Permintaan Fitur & Proposal Alur Kerja',
  ];

  final List<String> _severityLevels = [
    'Rendah (Kosmetik minor / Saran)',
    'Sedang (Hambatan alur kerja)',
    'Tinggi (Pemblokir kritis / Masalah data)',
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicianName();
  }

  Future<void> _loadTechnicianName() async {
    final name = await _authHelper.getUsername();
    if (mounted) {
      setState(() {
        _technicianName = name;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Luar Biasa — Sangat efisien untuk operasional bengkel';
      case 4:
        return 'Bagus — Alat yang dapat diandalkan untuk tugas harian';
      case 3:
        return 'Cukup — Fungsional tetapi butuh sedikit perbaikan alur kerja';
      case 2:
        return 'Kurang — Menemui hambatan operasional atau respon lambat';
      case 1:
        return 'Kritis — Masalah besar menghambat tugas perbaikan';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 650));

    // Generate random mock diagnostic ticket ID
    final randomId = 1000 + Random().nextInt(9000);
    final ticketNumber = 'SF-$randomId';

    // Show local notification as feedback submission receipt
    await NotificationHelper().showNotification(
      id: 201,
      title: 'Umpan Balik Dicatat (Tiket $ticketNumber)',
      body: 'Evaluasi bengkel perbaikan Anda telah direkam ke dalam sistem diagnostik SmartFix.',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Color(0xFF14B8A6), size: 48),
          title: const Text('Umpan Balik Terkirim!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terima kasih, $_technicianName! Evaluasi dan laporan bug Anda telah dicatat di Tiket #$ticketNumber.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Ref Tiket: $ticketNumber',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kategori: $_selectedCategory • Tingkat Keparahan: $_selectedSeverity',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _titleController.clear();
                _descriptionController.clear();
                _suggestionsController.clear();
                setState(() {
                  _rating = 5;
                  _selectedCategory = _categories.first;
                  _selectedSeverity = 'Sedang (Hambatan alur kerja)';
                });
              },
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
        title: const Text('Umpan Balik Aplikasi & Laporan Bug'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Workshop Diagnostics Banner ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.15),
                      const Color(0xFF14B8A6).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build_circle, color: Color(0xFF0F766E), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Pusat Operasi Bengkel SmartFix',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kinerja Bengkel Servis & Diagnostik Bug',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bantu kami mengoptimalkan pelacakan inventaris suku cadang, estimasi waktu perbaikan, dan alur kerja bengkel untuk teknisi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Star Rating Section ───────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Pengalaman Keseluruhan Aplikasi Bengkel Perbaikan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            iconSize: 38,
                            icon: Icon(
                              starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _rating = starIndex),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingLabel(_rating),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Category Dropdown ─────────────────────────────────────────
              Text(
                'Kategori Umpan Balik',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // ── Severity Level (If applicable) ────────────────────────────
              Text(
                'Dampak Masalah / Keparahan',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _severityLevels[1],
                items: _severityLevels
                    .map((sev) => DropdownMenuItem(
                          value: sev,
                          child: Text(sev, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSeverity = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.report_problem_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // ── Title / Summary ───────────────────────────────────────────
              Text(
                'Ringkasan Masalah / Subjek',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'mis., Pemindai barcode butuh beberapa percobaan pada modul kamera kecil',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.short_text_rounded),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Silakan masukkan ringkasan singkat' : null,
              ),

              const SizedBox(height: 16),

              // ── Detailed Experience / Bug Observations ─────────────────────
              Text(
                'Pengalaman & Observasi Detail',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Deskripsikan situasi bengkel, pesan error, atau bagaimana fitur bekerja...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Silakan berikan observasi detail'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Suggestions for App Improvement ────────────────────────────
              Text(
                'Saran untuk Efisiensi Bengkel',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _suggestionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Perubahan atau tambahan apa yang dapat membantu teknisi memperbaiki lebih cepat dan mengatur inventaris lebih baik?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Silakan bagikan saran untuk meningkatkan aplikasi'
                    : null,
              ),

              const SizedBox(height: 24),

              // ── Diagnostics Meta Info ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Telemetri perangkat (OS, latensi jaringan, build aplikasi) digabungkan otomatis untuk ulasan diagnostik.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ─────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Mencatat Tiket...' : 'Kirim Umpan Balik Bengkel & Laporan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
