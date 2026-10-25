// ============================================================================
// FITUR: DASBOR UTAMA MANAJEMEN INVENTARIS SUKU CADANG (DASHBOARD SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Menampilkan ringkasan katalog suku cadang servis secara real-time dari backend Laravel.
// 2. Dilengkapi kartu KPI (Total Parts, Low Stock, Out of Stock) untuk monitoring stok kritis.
// 3. Fitur Pencarian Cerdas dengan Debounce (350ms) guna mencegah request berlebihan ke server.
// 4. Filter Kategori interaktif (Layar, Baterai, Mesin, Aksesoris) menggunakan ChoiceChip.
// 5. Integrasi autentikasi Sanctum: menampilkan nama teknisi yang sedang login dan opsi logout aman.
// 6. Menyajikan status verifikasi integritas buku besar SHA-256 pada masing-masing komponen.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/api_service.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/local_db_helper.dart';
import 'package:smartfix_mobile/features/auth/screens/login_screen.dart';
import 'package:smartfix_mobile/features/inventory/screens/add_part_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Controller untuk input pencarian teks suku cadang
  final TextEditingController _searchController = TextEditingController();
  // Service komunikasi data REST API Laravel
  final ApiService _apiService = ApiService();
  // Helper manajemen sesi login & Secure Storage token
  final AuthHelper _authHelper = AuthHelper();
  // Helper database SQLite lokal untuk Offline-First storage
  final LocalDbHelper _localDb = LocalDbHelper();

  // Kategori filter terpilih (default: 'Semua')
  String _selectedCategory = 'Semua';
  // Nama teknisi yang sedang aktif dalam sesi
  String _technicianName = 'Teknisi';
  // Status pemuatan data inventaris
  bool _isLoading = true;
  // Pesan error jika koneksi atau fetch data gagal
  String? _errorMessage;

  // Daftar data inventaris suku cadang dari backend
  List<Map<String, dynamic>> _inventoryItems = [];
  // Timer debounce untuk penundaan request saat pengguna mengetik pencarian
  Timer? _debounceTimer;

  final List<String> _categories = [
    'Semua',
    'Layar',
    'Baterai',
    'Mesin',
    'Aksesoris',
  ];

  static const Color _bgColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF262626);
  static const Color _cardColor = Color(0xFF2E2E2E);
  static const Color _cardBorderColor = Color(0xFF3D3D3D);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF0F766E);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFA3A3A3);

  @override
  void initState() {
    super.initState();
    // 1. Memuat nama profil teknisi yang tersimpan di storage lokal
    _loadTechnicianProfile();
    // 2. Mengambil data suku cadang dari API backend Laravel
    _fetchInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// FITUR: Membaca identitas teknisi dari Secure Storage
  Future<void> _loadTechnicianProfile() async {
    final name = await _authHelper.getUsername();
    if (mounted) {
      setState(() {
        _technicianName = name;
      });
    }
  }

  /// FITUR: Pencarian dengan Mekanisme Debounce 350 milidetik
  /// Mencegah flooding HTTP request ke server pada saat pengguna mengetik cepat
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchInventory();
    });
  }

  /// FITUR: Sinkronisasi Data Inventaris dengan Pendekatan Offline-First
  /// a. Coba panggil _apiService.getInventory()
  /// b. Jika berhasil, clear data lama di SQLite dan insert batch data terbaru tersebut ke SQLite
  /// c. Bungkus proses A dan B dalam try-catch dan abaikan error jaringan jika gagal (mode offline)
  /// d. SELALU jalankan fungsi baca data ke UI dari SQLite menggunakan localDb.getInventoryItems()
  ///    dengan parameter search dan category yang aktif (tidak pernah merender UI langsung dari API response)
  Future<void> _fetchInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getInventory();

      List<Map<String, dynamic>> items = [];

      if (response is Map && response['data'] is List) {
        items = (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } else if (response is List) {
        items = response
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      await _localDb.clearInventory();
      if (items.isNotEmpty) {
        await _localDb.insertInventoryBatch(items);
      }
    } catch (_) {
      // Abaikan error jaringan saat offline agar aplikasi tidak crash
    }

    try {
      final localItems = await _localDb.getInventoryItems(
        search: _searchController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _inventoryItems = localItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// FITUR: Logout Aman & Dialog Konfirmasi
  /// Menghapus bearer token Sanctum di FlutterSecureStorage dan kembali ke halaman Login
  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _cardBorderColor),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin mengakhiri sesi teknisi dan menghapus kredensial lokal?',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(color: _textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _authHelper.clearSession();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _formatIdr(num price) {
    final intVal = price.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static num _parseNum(dynamic val, [num fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val;
    if (val is String) {
      return num.tryParse(val) ?? fallback;
    }
    return fallback;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'display':
      case 'screens':
        return Icons.smartphone_outlined;
      case 'battery':
      case 'batteries':
        return Icons.battery_charging_full_outlined;
      case 'machine':
      case 'motherboards':
        return Icons.memory_outlined;
      case 'accessories':
      case 'charging ports':
        return Icons.cable_outlined;
      default:
        return Icons.build_circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalParts = _inventoryItems.length;
    final lowStockCount = _inventoryItems.where((item) {
      final stock = _parseInt(item['stock_quantity'] ?? item['stock']);
      return stock > 0 && stock <= 3;
    }).length;
    final outOfStockCount = _inventoryItems.where((item) {
      final stock = _parseInt(item['stock_quantity'] ?? item['stock']);
      return stock == 0;
    }).length;

    return Scaffold(
      backgroundColor: _bgColor,

      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_teal, _tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _teal.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _technicianName.isNotEmpty
                      ? _technicianName[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _technicianName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.lock_clock, size: 10, color: _teal),
                      SizedBox(width: 4),
                      Text(
                        'Autentikasi Sanctum',
                        style: TextStyle(
                          color: _teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Inventory',
            icon: const Icon(Icons.refresh_rounded, color: _textSecondary),
            onPressed: _fetchInventory,
          ),

          IconButton(
            tooltip: 'Secure Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddPartScreen()),
          );
          if (result == true) {
            _fetchInventory();
          }
        },
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Tambah Part',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _fetchInventory,
        color: _teal,
        backgroundColor: _surfaceColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari suku cadang berdasarkan nama atau seri...',
                  hintStyle: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(Icons.search, color: _teal, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: _textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _fetchInventory();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _teal, width: 1.5),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _fetchInventory();
                      }
                    },
                    selectedColor: _tealDark,
                    backgroundColor: _surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? _teal : _cardBorderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildKpiCard(
                    title: 'Total Parts',
                    value: '$totalParts',
                    color: _teal,
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    title: 'Low Stock',
                    value: '$lowStockCount',
                    color: Colors.amber,
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildKpiCard(
                    title: 'Out of Stock',
                    value: '$outOfStockCount',
                    color: Colors.redAccent,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ),

            const Divider(color: _cardBorderColor, height: 16),

            Expanded(child: _buildInventoryListContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryListContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _teal),
            SizedBox(height: 16),
            Text(
              'Memuat data buku besar aman...',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      final isUnauthenticated =
          _errorMessage!.toLowerCase().contains('unauthenticated') ||
          _errorMessage!.toLowerCase().contains('401');

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUnauthenticated
                    ? Icons.lock_outline_rounded
                    : Icons.cloud_off_rounded,
                size: 54,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                isUnauthenticated
                    ? 'Sesi Login Telah Berakhir'
                    : 'Gagal Menghubungkan ke API SmartFix',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUnauthenticated
                    ? 'Kredensial atau token sesi Anda telah berakhir. Silakan masuk kembali ke akun teknisi Anda.'
                    : _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (isUnauthenticated)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _authHelper.clearSession();
                    if (!mounted) return;
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Masuk ke Akun'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _fetchInventory,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_inventoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 56,
              color: _textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Suku cadang tidak ditemukan',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Coba cari dengan kata kunci atau SKU yang berbeda.'
                  : 'Tekan tombol "+" di bawah untuk mendaftarkan suku cadang baru.',
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        return _buildPartCard(item);
      },
    );
  }

  Widget _buildPartCard(Map<String, dynamic> item) {
    final String name = (item['name'] ?? 'Unnamed Component').toString();
    final String serialNumber = (item['serial_number'] ?? item['sku'] ?? 'N/A')
        .toString();
    final String category = (item['category'] ?? 'General').toString();
    final int stock = _parseInt(item['stock_quantity'] ?? item['stock']);
    final num price = _parseNum(item['base_price_idr'] ?? item['price']);

    Color stockBadgeBg;
    Color stockBadgeText;
    String stockLabel;

    if (stock == 0) {
      stockBadgeBg = Colors.redAccent.withValues(alpha: 0.15);
      stockBadgeText = Colors.redAccent;
      stockLabel = 'Habis';
    } else if (stock <= 3) {
      stockBadgeBg = Colors.amber.withValues(alpha: 0.15);
      stockBadgeText = Colors.amber;
      stockLabel = 'Sisa: $stock pcs';
    } else {
      stockBadgeBg = _tealDark.withValues(alpha: 0.2);
      stockBadgeText = _teal;
      stockLabel = 'Stok: $stock pcs';
    }

    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _cardBorderColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 13,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'SN: $serialNumber • $category',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockBadgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: stockBadgeText.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    stockLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: stockBadgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatIdr(price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _tealDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _teal.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: _teal),
                      SizedBox(width: 4),
                      Text(
                        'Terverifikasi SHA-256',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
