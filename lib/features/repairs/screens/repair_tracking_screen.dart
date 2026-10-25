// ============================================================================
// FITUR: PELACAKAN TIKET SERVIS & WORK ORDER (REPAIR TRACKING SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Manajemen Alur Kerja Servis: Memantau siklus hidup tiket perbaikan perangkat pelanggan
//    (Status: MENUNGGU -> PROSES -> SELESAI / BATAL).
// 2. Pemotongan Stok Otomatis: Saat tiket ditandai 'SELESAI', sistem secara otomatis memotong stok
//    suku cadang yang terpakai pada backend database (Atomic Stock Deduction).
// 3. Pencarian & Filter Status Interaktif: Memudahkan teknisi menyaring tiket berdasarkan status
//    pengerjaan maupun kata kunci pencarian nama pelanggan / model gadget.
// 4. Modal Formulir Tiket Servis Baru: Memungkinkan input data pelanggan, jenis unit, keluhan teknis,
//    estimasi biaya perbaikan, serta pemilihan komponen suku cadang langsung dari katalog.
// 5. Konversi Kurs Kontekstual Real-Time: Fitur kalkulasi instan biaya tiket ke mata uang
//    internasional (USD, EUR, GBP, AUD) via API kurs publik dengan offline fallback resilience.
// 6. Sinkronisasi Real-Time: Terhubung langsung dengan Laravel REST API via ApiService.
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:smartfix_mobile/core/api_service.dart';

class RepairTrackingScreen extends StatefulWidget {
  const RepairTrackingScreen({super.key});

  @override
  State<RepairTrackingScreen> createState() => _RepairTrackingScreenState();
}

class _RepairTrackingScreenState extends State<RepairTrackingScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Daftar data tiket servis dari server
  List<dynamic> _workOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  // Status filter tiket (default: 'SEMUA')
  String _selectedStatusFilter = 'SEMUA';

  // ── State Nilai Tukar Kurs (Currency Exchange Rates) ─────────────────────────
  // Kurs acuan default (fallback offline) berbasis 1 USD jika perangkat tanpa koneksi
  Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'IDR': 16250.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'AUD': 1.54,
  };
  bool _isRatesLive = false;
  bool _isFetchingRates = false;
  DateTime? _ratesLastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchWorkOrders();
    _fetchExchangeRates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// FITUR: Mengambil Data Kurs Valuta Asing Real-Time dari open.er-api.com
  /// Dilengkapi proteksi try-catch & offline fallback agar tidak pernah crash saat offline
  Future<void> _fetchExchangeRates() async {
    if (_isFetchingRates) return;
    _isFetchingRates = true;

    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['rates'] is Map) {
          final rawRates = data['rates'] as Map;
          if (!mounted) return;
          setState(() {
            _exchangeRates = {
              'USD': 1.0,
              'IDR': (rawRates['IDR'] as num?)?.toDouble() ?? 16250.0,
              'EUR': (rawRates['EUR'] as num?)?.toDouble() ?? 0.92,
              'GBP': (rawRates['GBP'] as num?)?.toDouble() ?? 0.79,
              'AUD': (rawRates['AUD'] as num?)?.toDouble() ?? 1.54,
            };
            _isRatesLive = true;
            _ratesLastUpdated = DateTime.now();
          });
        }
      }
    } catch (e) {
      // Tetap gunakan fallback data kurs lokal jika offline tanpa melempar exception ke UI
      debugPrint('Exchange rate API offline / timeout: $e. Menggunakan fallback offline.');
    } finally {
      _isFetchingRates = false;
    }
  }

  /// FITUR: Mengambil Daftar Tiket Servis dari API Backend Laravel
  /// Mendukung filter berdasarkan status (SEMUA/MENUNGGU/PROSES/SELESAI) dan kata kunci pencarian
  Future<void> _fetchWorkOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.getWorkOrders(
        status: _selectedStatusFilter == 'SEMUA' ? null : _selectedStatusFilter,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'];
      }

      if (!mounted) return;
      setState(() {
        _workOrders = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// FITUR: Menyelesaikan Tiket Servis (Mark as Completed)
  /// Memicu pemotongan stok otomatis pada backend untuk komponen suku cadang yang digunakan
  Future<void> _completeWorkOrder(
    dynamic workOrderId,
    String customerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Selesai Servis'),
        content: Text(
          'Tandai perbaikan untuk "$customerName" sebagai SELESAI?\n\n'
          'Sistem akan otomatis memotong stok suku cadang terkait dari basis data inventaris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi Selesai'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.completeWorkOrder(workOrderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perbaikan berhasil diselesaikan dan stok part telah dipotong.',
          ),
          backgroundColor: Color(0xFF0F766E),
        ),
      );
      _fetchWorkOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan perbaikan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openCreateWorkOrderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateWorkOrderSheet(
        onCreated: () {
          _fetchWorkOrders();
        },
      ),
    );
  }

  double _parseAmountToDouble(dynamic rawAmount) {
    if (rawAmount == null) return 0.0;
    if (rawAmount is num) return rawAmount.toDouble();
    return double.tryParse(
          rawAmount.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
  }

  String _formatRupiah(dynamic rawAmount) {
    if (rawAmount == null) return 'Rp 0';
    num amount;
    if (rawAmount is num) {
      amount = rawAmount;
    } else {
      amount =
          num.tryParse(
            rawAmount.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
    }
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String _formatDecimal(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    final formattedInt = buffer.toString().split('').reversed.join('');
    return '$formattedInt.$decPart';
  }

  /// FITUR: Modal Bottom Sheet Konversi Kurs Mata Uang Internasional
  /// Mengonversi estimasi biaya tiket (IDR) ke USD, EUR, GBP, dan AUD secara instan
  void _showCurrencyConversionSheet(
    dynamic rawCost,
    String customerName,
    String deviceModel,
  ) {
    final double costInIdr = _parseAmountToDouble(rawCost);
    final double idrRate = _exchangeRates['IDR'] ?? 16250.0;
    final double validIdrRate = idrRate > 0 ? idrRate : 16250.0;

    // Kalkulasi konversi relatif terhadap USD
    final double costInUsd = costInIdr / validIdrRate;
    final double costInEur = costInUsd * (_exchangeRates['EUR'] ?? 0.92);
    final double costInGbp = costInUsd * (_exchangeRates['GBP'] ?? 0.79);
    final double costInAud = costInUsd * (_exchangeRates['AUD'] ?? 1.54);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.currency_exchange_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konversi Kurs Internasional',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$customerName • $deviceModel',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Kartu Nilai Asal IDR & Status Kurs
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.35),
                      const Color(0xFF1E293B).withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimasi Biaya Dasar (IDR)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _isRatesLive
                                ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isRatesLive
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                                  : Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRatesLive
                                    ? Icons.wifi_rounded
                                    : Icons.wifi_off_rounded,
                                size: 10,
                                color: _isRatesLive
                                    ? const Color(0xFF4ADE80)
                                    : Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isRatesLive ? 'Live API (USD)' : 'Kurs Cadangan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isRatesLive
                                      ? const Color(0xFF4ADE80)
                                      : Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(rawCost),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ADE80),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Acuan: 1 USD ≈ ${_formatRupiah(validIdrRate)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                        if (_ratesLastUpdated != null)
                          Text(
                            'Diperbarui: ${_ratesLastUpdated!.hour.toString().padLeft(2, '0')}:${_ratesLastUpdated!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Estimasi dalam Valuta Asing:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),

              // Daftar Konversi 4 Mata Uang Utama
              _buildCurrencyRow(
                code: 'USD',
                symbol: '\$',
                name: 'Dolar Amerika Serikat',
                subtitle: 'Patokan Pabrikan Global & Sparepart OEM',
                convertedValue: '\$ ${_formatDecimal(costInUsd)}',
                color: const Color(0xFF38BDF8),
                flag: '🇺🇸',
              ),
              const SizedBox(height: 8),

              _buildCurrencyRow(
                code: 'EUR',
                symbol: '€',
                name: 'Euro Uni Eropa',
                subtitle: 'Alat Presisi Mikroskop & Fluks Jerman',
                convertedValue: '€ ${_formatDecimal(costInEur)}',
                color: const Color(0xFFA78BFA),
                flag: '🇪🇺',
              ),
              const SizedBox(height: 8),

              _buildCurrencyRow(
                code: 'GBP',
                symbol: '£',
                name: 'Poundsterling Britania',
                subtitle: 'Lisensi Perangkat Lunak & Diagnostik UK',
                convertedValue: '£ ${_formatDecimal(costInGbp)}',
                color: const Color(0xFFF472B6),
                flag: '🇬🇧',
              ),
              const SizedBox(height: 8),

              _buildCurrencyRow(
                code: 'AUD',
                symbol: 'A\$',
                name: 'Dolar Australia',
                subtitle: 'Hub Logistik Pasifik & Regional Oseania',
                convertedValue: 'A\$ ${_formatDecimal(costInAud)}',
                color: const Color(0xFFFBBF24),
                flag: '🇦🇺',
              ),
              const SizedBox(height: 16),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text(
                    'Tutup Rincian Kurs',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyRow({
    required String code,
    required String symbol,
    required String name,
    required String subtitle,
    required String convertedValue,
    required Color color,
    required String flag,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              flag,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            convertedValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SELESAI':
        return const Color(0xFF22C55E);
      case 'IN_PROGRESS':
      case 'DIKERJAKAN':
        return const Color(0xFF0284C7);
      case 'PENDING':
      case 'MENUNGGU':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SELESAI':
        return 'Selesai';
      case 'IN_PROGRESS':
      case 'DIKERJAKAN':
        return 'Dikerjakan';
      case 'PENDING':
      case 'MENUNGGU':
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Perbaikan Pelanggan'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchWorkOrders();
              _fetchExchangeRates();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Catat Perbaikan Baru'),
        onPressed: _openCreateWorkOrderDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchWorkOrders(),
              decoration: InputDecoration(
                hintText: 'Cari pelanggan, tipe HP, atau nomor tiket...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0F766E),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchWorkOrders();
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('SEMUA', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Menunggu'),
                const SizedBox(width: 8),
                _buildFilterChip('IN_PROGRESS', 'Dikerjakan'),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETED', 'Selesai'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _fetchWorkOrders(),
                  _fetchExchangeRates(),
                ]);
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat tiket perbaikan:\n$_errorMessage',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              onPressed: () {
                                _fetchWorkOrders();
                                _fetchExchangeRates();
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : _workOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 54,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada tiket perbaikan.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ketuk tombol di bawah untuk mencatat perbaikan baru.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Catat Perbaikan'),
                            onPressed: _openCreateWorkOrderDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _workOrders.length,
                      itemBuilder: (ctx, index) {
                        final wo = _workOrders[index];
                        final id = wo['id'];
                        final customerName = wo['customer_name'] ?? 'Pelanggan';
                        final customerPhone = wo['customer_phone'] ?? '-';
                        final deviceModel =
                            wo['device_model'] ?? 'Perangkat Smartphone';
                        final issue =
                            wo['issue_description'] ?? 'Pengecekan umum';
                        final status = (wo['status'] ?? 'PENDING').toString();
                        final cost = wo['estimated_cost'];
                        final isCompleted = status.toUpperCase() == 'COMPLETED';
                        final statusColor = _getStatusColor(status);
                        final parts = (wo['parts'] is List)
                            ? (wo['parts'] as List)
                            : [];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCompleted
                                  ? const Color(0xFF22C55E)
                                        .withValues(alpha: 0.3)
                                  : Colors.white12,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#WO-$id',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCompleted
                                                ? Icons.check_circle_rounded
                                                : Icons.timelapse_rounded,
                                            size: 13,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _getStatusLabel(status),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Color(0x1F0F766E),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone_iphone_rounded,
                                                size: 14,
                                                color: Colors.white54,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                deviceModel,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF818CF8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (customerPhone != '-')
                                            Text(
                                              'WhatsApp/Telp: $customerPhone',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Gejala: $issue',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                if (parts.isNotEmpty) ...[
                                  const Text(
                                    'Suku Cadang Terpasang:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: parts.map<Widget>((p) {
                                      final name =
                                          p['name'] ?? 'Part #${p['id'] ?? ''}';
                                      final qty =
                                          p['quantity'] ??
                                          (p['pivot']?['quantity'] ?? 1);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F766E)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF0F766E)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          '$qty x $name',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2DD4BF),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                const Divider(height: 16),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Estimasi Biaya',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _formatRupiah(cost),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF4ADE80),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _showCurrencyConversionSheet(
                                                cost,
                                                customerName,
                                                deviceModel,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F766E)
                                                      .withValues(alpha: 0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(0xFF2DD4BF)
                                                        .withValues(alpha: 0.4),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.currency_exchange_rounded,
                                                      size: 13,
                                                      color: Color(0xFF2DD4BF),
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Kurs',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF2DD4BF),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    if (!isCompleted)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0F766E,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Tandai Selesai',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () => _completeWorkOrder(
                                          id,
                                          customerName,
                                        ),
                                      )
                                    else
                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 16,
                                            color: Color(0xFF22C55E),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Perbaikan Selesai',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0F766E),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = value;
          });
          _fetchWorkOrders();
        }
      },
    );
  }
}

class _CreateWorkOrderSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateWorkOrderSheet({required this.onCreated});

  @override
  State<_CreateWorkOrderSheet> createState() => _CreateWorkOrderSheetState();
}

class _CreateWorkOrderSheetState extends State<_CreateWorkOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  final ApiService _api = ApiService();
  bool _isSubmitting = false;
  bool _isLoadingParts = true;

  List<dynamic> _inventoryParts = [];
  final List<Map<String, dynamic>> _selectedParts = [];

  @override
  void initState() {
    super.initState();
    _fetchInventoryParts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deviceCtrl.dispose();
    _issueCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInventoryParts() async {
    try {
      final response = await _api.getInventory();
      List<dynamic> items = [];
      if (response is List) {
        items = response;
      } else if (response is Map && response['data'] is List) {
        items = response['data'];
      }
      if (!mounted) return;
      setState(() {
        _inventoryParts = items;
        _isLoadingParts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingParts = false);
    }
  }

  void _addPartRow() {
    if (_inventoryParts.isEmpty) return;
    setState(() {
      final first = _inventoryParts.first;
      _selectedParts.add({
        'part_id': first['id'],
        'name': first['name'],
        'quantity': 1,
        'max_stock': first['stock'] ?? 10,
      });
    });
  }

  void _removePartRow(int index) {
    setState(() {
      _selectedParts.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
      final partsPayload = _selectedParts
          .map((p) => {'part_id': p['part_id'], 'quantity': p['quantity']})
          .toList();

      final data = {
        'customer_name': _nameCtrl.text.trim(),
        'customer_phone': _phoneCtrl.text.trim(),
        'device_model': _deviceCtrl.text.trim(),
        'issue_description': _issueCtrl.text.trim(),
        'estimated_cost': cost,
        'status': 'PENDING',
        'parts': partsPayload,
      };

      await _api.createWorkOrder(data);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket perbaikan pelanggan berhasil dicatat!'),
          backgroundColor: Color(0xFF0F766E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencatat perbaikan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Catat Status Perbaikan Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Hubungkan perbaikan pelanggan dengan inventaris suku cadang.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon / WhatsApp',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _deviceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model Perangkat Smartphone *',
                  hintText: 'Contoh: iPhone 13 Pro / Samsung Galaxy A54',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Model perangkat wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _issueCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kerusakan / Gejala *',
                  hintText: 'Contoh: Layar pecah, sentuhan tidak responsif',
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Deskripsi kerusakan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Estimasi Biaya Perbaikan (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suku Cadang yang Digunakan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Pilih Part',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _isLoadingParts || _inventoryParts.isEmpty
                        ? null
                        : _addPartRow,
                  ),
                ],
              ),
              if (_isLoadingParts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_selectedParts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'Belum ada part dipilih. Ketuk "+ Pilih Part" untuk menghubungkan komponen inventaris.',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedParts.length,
                  itemBuilder: (ctx, index) {
                    final item = _selectedParts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value:
                                    int.tryParse(
                                      item['part_id']?.toString() ?? '',
                                    ) ??
                                    0,
                                items: _inventoryParts
                                    .map<DropdownMenuItem<int>>((part) {
                                      final pId =
                                          int.tryParse(
                                            part['id']?.toString() ?? '',
                                          ) ??
                                          0;
                                      final pName = part['name'].toString();
                                      final pStock = part['stock'] ?? 0;
                                      return DropdownMenuItem<int>(
                                        value: pId,
                                        child: Text(
                                          '$pName (Stok: $pStock)',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    })
                                    .toList(),
                                onChanged: (newId) {
                                  if (newId == null) return;
                                  final found = _inventoryParts.firstWhere(
                                    (p) => p['id'] == newId,
                                  );
                                  setState(() {
                                    item['part_id'] = newId;
                                    item['name'] = found['name'];
                                    item['max_stock'] = found['stock'] ?? 10;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () {
                                  if (item['quantity'] > 1) {
                                    setState(() => item['quantity']--);
                                  }
                                },
                              ),
                              Text(
                                '${item['quantity']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () {
                                  final maxStk = item['max_stock'] ?? 99;
                                  if (item['quantity'] < maxStk) {
                                    setState(() => item['quantity']++);
                                  }
                                },
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () => _removePartRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Menyimpan Tiket...'
                        : 'Simpan Tiket Perbaikan',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
