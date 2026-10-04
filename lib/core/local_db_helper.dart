import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database helper for offline data storage and caching.
class LocalDbHelper {
  static const String _dbName = 'smartfix_inventory.db';
  static const int _dbVersion = 1;

  // Singleton instance
  static final LocalDbHelper _instance = LocalDbHelper._internal();
  factory LocalDbHelper() => _instance;
  LocalDbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Inventory table
    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Repair tickets table
    await db.execute('''
      CREATE TABLE repair_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_model TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Insert an item into the inventory table
  Future<int> insertInventory(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(
      'inventory_items',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all inventory items
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    final db = await database;
    return await db.query('inventory_items', orderBy: 'name ASC');
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
