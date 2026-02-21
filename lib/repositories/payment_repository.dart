import 'package:sqflite/sqflite.dart';
import '../models/payment_model.dart';
import '../services/database_helper.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create payment
  Future<Payment> createPayment(Payment payment) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return payment.copyWith(id: id);
  }

  // Get all payments for an order
  Future<List<Payment>> getOrderPayments(int orderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  // Get all payments for a customer (across all orders)
  Future<List<Payment>> getCustomerPayments(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  // Get single payment
  Future<Payment?> getPaymentById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  // Update payment
  Future<int> updatePayment(Payment payment) async {
    final db = await _dbHelper.database;
    return await db.update(
      'payments',
      payment.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // Delete payment
  Future<int> deletePayment(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total paid for an order
  Future<double> getOrderTotalPaid(int orderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE order_id = ?',
      [orderId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total paid by a customer (across all orders)
  Future<double> getCustomerTotalPaid(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE customer_id = ?',
      [customerId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get payment count for customer
  Future<int> getCustomerPaymentCount(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payments WHERE customer_id = ?',
      [customerId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}