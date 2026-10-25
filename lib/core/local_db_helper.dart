import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database Helper SQLite untuk penyimpanan data lokal (Offline Storage / Offline-First).
/// Memisahkan database offline (katalog part) dari transaksi online (tiket perbaikan).
///
/// Tabel:
/// - `inventory_items`: id, name, category, stock, price, sku
class LocalDbHelper {
  static const String _dbName = 'smartfix_inventory.db';
  static const int _dbVersion = 2;

  // Pola Singleton agar koneksi database SQLite hanya dibuat satu kali
  static final LocalDbHelper _instance = LocalDbHelper._internal();
  factory LocalDbHelper() => _instance;
  LocalDbHelper._internal();

  static Database? _database;

  /// Mengambil instance database SQLite aktif atau menginisialisasinya jika belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Membuka file database SQLite di direktori penyimpanan lokal perangkat
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat skema tabel katalog part saat database pertama kali diinisialisasi
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        stock INTEGER,
        price REAL,
        sku TEXT
      )
    ''');
  }

  /// Menangani migrasi skema database SQLite saat versi ditingkatkan
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS inventory_items');
      await db.execute('DROP TABLE IF EXISTS repair_tickets');
      await _onCreate(db, newVersion);
    }
  }

  /// Menghapus seluruh data lama pada tabel inventory_items
  Future<int> clearInventory() async {
    final db = await database;
    return await db.delete('inventory_items');
  }

  /// Menyimpan data JSON suku cadang dari API secara massal (batch insert) ke SQLite
  Future<void> insertInventoryBatch(List<Map> items) async {
    final db = await database;
    final batch = db.batch();

    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw);

      final dynamic rawStock = item['stock'] ?? item['stock_quantity'] ?? 0;
      final int stock = rawStock is int
          ? rawStock
          : (int.tryParse(rawStock.toString()) ?? 0);

      final dynamic rawPrice = item['price'] ?? item['base_price_idr'] ?? 0;
      final double price = rawPrice is num
          ? rawPrice.toDouble()
          : (double.tryParse(rawPrice.toString()) ?? 0.0);

      final String sku =
          (item['sku'] ?? item['serial_number'] ?? '').toString();
      final String name = (item['name'] ?? '').toString();
      final String category = (item['category'] ?? '').toString();

      final data = <String, dynamic>{
        'name': name,
        'category': category,
        'stock': stock,
        'price': price,
        'sku': sku,
      };

      if (item['id'] != null) {
        final id = item['id'];
        data['id'] = id is int ? id : int.tryParse(id.toString());
      }

      batch.insert(
        'inventory_items',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// FITUR: Menyimpan 1 suku cadang baru langsung ke database SQLite lokal (Offline Storage)
  Future<int> insertPart({
    required String name,
    required String category,
    required int stock,
    required double price,
    required String sku,
  }) async {
    final db = await database;
    return await db.insert(
      'inventory_items',
      {
        'name': name,
        'category': category,
        'stock': stock,
        'price': price,
        'sku': sku,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil daftar suku cadang langsung dari SQLite dengan filter pencarian dan kategori
  Future<List<Map<String, dynamic>>> getInventoryItems({
    String? search,
    String? category,
  }) async {
    final db = await database;

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    // Filter berdasarkan teks pencarian pada nama atau SKU
    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR sku LIKE ?)');
      final term = '%${search.trim()}%';
      whereArgs.add(term);
      whereArgs.add(term);
    }

    // Filter berdasarkan kategori suku cadang (mengabaikan Semua / All)
    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Semua' &&
        category != 'All') {
      whereClauses.add('category = ? COLLATE NOCASE');
      whereArgs.add(category.trim());
    }

    final String? where =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    return await db.query(
      'inventory_items',
      where: where,
      whereArgs: whereClauses.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
  }

  /// Menutup koneksi database SQLite jika diperlukan
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
