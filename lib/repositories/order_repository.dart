import 'package:sqflite/sqflite.dart';
import '../models/order_model.dart';
import '../services/database_helper.dart';

class OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create order
  Future<Order> createOrder(Order order) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'orders',
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return order.copyWith(id: id);
  }

  // Get all orders for a customer
  Future<List<Order>> getCustomerOrders(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Get single order
  Future<Order?> getOrderById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(int customerId, String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'orders',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, status],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Get pending orders count for customer
  Future<int> getPendingOrdersCount(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE customer_id = ? AND status != ?',
      [customerId, Order.statusCollected],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Update order
  Future<int> updateOrder(Order order) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      order.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // Update order status
  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Update payment amount
  Future<int> updatePayment(int orderId, double paidAmount) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      {
        'paid_amount': paidAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Delete order
  Future<int> deleteOrder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all orders (for admin/overview)
  Future<List<Order>> getAllOrders() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // Get overdue orders
  Future<List<Order>> getOverdueOrders() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'orders',
      where: 'due_date < ? AND status != ?',
      whereArgs: [now, Order.statusCollected],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }
}