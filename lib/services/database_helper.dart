import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tailorpro.db');
    return _database!;
  }

  static const int _version = 4;   // ← Changed to version 4 for cloud sync support

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Previous upgrades for orders table
      await db.execute('ALTER TABLE orders ADD COLUMN order_title TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN stage TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN actual_delivery_date TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN fabric_details TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN delivery_date TEXT');
      await db.execute('UPDATE orders SET delivery_date = due_date WHERE delivery_date IS NULL');
    }

    if (oldVersion < 3) {
      // Create payments table (if not exists)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          customer_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          payment_method TEXT NOT NULL,
          payment_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_payment_order ON payments(order_id)');
      await db.execute('CREATE INDEX idx_payment_customer ON payments(customer_id)');
    }

    if (oldVersion < 4) {
      // NEW: Add columns needed for cloud sync (user_id, sync_status, etc.)
      await _addUserIdAndSyncColumns(db);
    }
  }

  // Add user_id and sync columns to all tables
  Future<void> _addUserIdAndSyncColumns(Database db) async {
    final tables = ['customers', 'measurements', 'orders', 'payments'];

    for (final table in tables) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN user_id TEXT');
        await db.execute('ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT "local_only"');
        await db.execute('ALTER TABLE $table ADD COLUMN local_temp_id TEXT');
        await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        debugPrint('✅ Added sync columns to table: $table');
      } catch (e) {
        debugPrint('Column may already exist in $table: $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        gender TEXT NOT NULL,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        order_number TEXT NOT NULL UNIQUE,
        order_title TEXT NOT NULL,
        status TEXT NOT NULL,
        stage TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        delivery_date TEXT NOT NULL,
        actual_delivery_date TEXT,
        notes TEXT,
        measurement_id INTEGER,
        item_type TEXT,
        quantity INTEGER DEFAULT 1,
        fabric_details TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (measurement_id) REFERENCES measurements (id) ON DELETE SET NULL
      )
    ''');

    // Measurements table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        measurement_type TEXT NOT NULL,
        measurements TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_phone ON customers(phone)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_name ON customers(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_customer ON orders(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_status ON orders(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_measurement_customer ON measurements(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_order ON payments(order_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_customer ON payments(customer_id)');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}