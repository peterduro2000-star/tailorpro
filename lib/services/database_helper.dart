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

  static const int _version = 6;

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureSyncColumns(db);
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Previous upgrades for orders table
      await db.execute('ALTER TABLE orders ADD COLUMN order_title TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN stage TEXT');
      await db
          .execute('ALTER TABLE orders ADD COLUMN actual_delivery_date TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN fabric_details TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN delivery_date TEXT');
      await db.execute(
          'UPDATE orders SET delivery_date = due_date WHERE delivery_date IS NULL');
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
      await db.execute(
          'CREATE INDEX idx_payment_customer ON payments(customer_id)');
    }

    if (oldVersion < 5) {
      // Add cloud sync metadata columns for older database versions.
      await _addUserIdAndSyncColumns(db);
    }

    if (oldVersion < 6) {
      await _addColumnIfMissing(db, 'orders', 'fabric_image_path', 'TEXT');
      await _addColumnIfMissing(db, 'orders', 'style_image_path', 'TEXT');
    }
  }

  // Add user_id and sync columns to all tables
  Future<void> _addUserIdAndSyncColumns(Database db) async {
    final tables = ['customers', 'measurements', 'orders', 'payments'];

    for (final table in tables) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN user_id TEXT');
        await db.execute('ALTER TABLE $table ADD COLUMN remote_id TEXT');
        await db.execute(
            'ALTER TABLE $table ADD COLUMN sync_status TEXT DEFAULT "local_only"');
        await db.execute('ALTER TABLE $table ADD COLUMN local_temp_id TEXT');
        await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT');
        debugPrint('✅ Added sync columns to table: $table');
      } catch (e) {
        debugPrint('Column may already exist in $table: $e');
      }
    }
  }

  Future<void> _ensureSyncColumns(Database db) async {
    final requiredColumns = {
      'customers': {
        'remote_id': 'TEXT',
        'user_id': 'TEXT',
        'sync_status': 'TEXT DEFAULT "local_only"',
        'local_temp_id': 'TEXT',
        'updated_at': 'TEXT',
      },
      'orders': {
        'remote_id': 'TEXT',
        'user_id': 'TEXT',
        'sync_status': 'TEXT DEFAULT "local_only"',
        'local_temp_id': 'TEXT',
        'updated_at': 'TEXT',
        'fabric_image_path': 'TEXT',
        'style_image_path': 'TEXT',
      },
      'measurements': {
        'remote_id': 'TEXT',
        'user_id': 'TEXT',
        'sync_status': 'TEXT DEFAULT "local_only"',
        'local_temp_id': 'TEXT',
        'updated_at': 'TEXT',
      },
      'payments': {
        'remote_id': 'TEXT',
        'user_id': 'TEXT',
        'sync_status': 'TEXT DEFAULT "local_only"',
        'local_temp_id': 'TEXT',
        'updated_at': 'TEXT',
      },
    };

    for (final entry in requiredColumns.entries) {
      final table = entry.key;
      final existingColumns = (await db.rawQuery('PRAGMA table_info($table)'))
          .map((row) => row['name'] as String)
          .toSet();

      for (final columnEntry in entry.value.entries) {
        if (!existingColumns.contains(columnEntry.key)) {
          try {
            await db.execute(
                'ALTER TABLE $table ADD COLUMN ${columnEntry.key} ${columnEntry.value}');
            debugPrint('✅ Added missing column ${columnEntry.key} to $table');
          } catch (e) {
            debugPrint(
                '⚠️ Failed to add missing column ${columnEntry.key} to $table: $e');
          }
        }
      }
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final existingColumns = (await db.rawQuery('PRAGMA table_info($table)'))
        .map((row) => row['name'] as String)
        .toSet();

    if (existingColumns.contains(column)) return;

    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        user_id TEXT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        gender TEXT NOT NULL,
        email TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT "local_only",
        local_temp_id TEXT
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        user_id TEXT,
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
        fabric_image_path TEXT,
        style_image_path TEXT,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT "local_only",
        local_temp_id TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (measurement_id) REFERENCES measurements (id) ON DELETE SET NULL
      )
    ''');

    // Measurements table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        user_id TEXT,
        customer_id INTEGER NOT NULL,
        measurement_type TEXT NOT NULL,
        measurements TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT "local_only",
        local_temp_id TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        user_id TEXT,
        order_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT "local_only",
        local_temp_id TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_phone ON customers(phone)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_name ON customers(name)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customer_remote_id ON customers(remote_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_order_customer ON orders(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_order_status ON orders(status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_order_remote_id ON orders(remote_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_measurement_customer ON measurements(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_measurement_remote_id ON measurements(remote_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_order ON payments(order_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_customer ON payments(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payment_remote_id ON payments(remote_id)');
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('payments');
    await db.delete('measurements');
    await db.delete('orders');
    await db.delete('customers');
    debugPrint('Database cleared');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
