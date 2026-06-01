import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import '../services/database_helper.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<Customer> createCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customer.copyWith(id: id);
  }
  //  NEW METHOD - Add this one
  Future<Map<String, dynamic>> getCustomerWithOrderCount(int customerId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT c.*, 
             COUNT(CASE WHEN o.status IN ('pending', 'in_progress') THEN 1 END) as pending_orders
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      WHERE c.id = ?
      GROUP BY c.id
    ''', [customerId]);

    if (result.isEmpty) {
      throw Exception('Customer with ID $customerId not found');
    }

    return result.first;
  }
  // Read all
  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  // Read single
  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  // Get all customers with order counts
  Future<List<Map<String, dynamic>>> getAllCustomersWithOrderCounts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT c.*, 
             COUNT(CASE WHEN o.status IN ('pending', 'in_progress') THEN 1 END) as pending_orders
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
    ''');
    return result;
  }

  // Update
  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Delete
  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get customer by phone
  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  // Check if customer exists
  Future<bool> customerExists(String phone) async {
    final customer = await getCustomerByPhone(phone);
    return customer != null;
  }

  // Get total customer count
  Future<int> getCustomerCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}