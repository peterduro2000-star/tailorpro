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

  // Get total paid by a customer from order balances.
  Future<double> getCustomerTotalPaid(int customerId) async {
    final db = await _dbHelper.database;
    final orderResult = await db.rawQuery(
      'SELECT SUM(paid_amount) as total FROM orders WHERE customer_id = ?',
      [customerId],
    );
    return (orderResult.first['total'] as num?)?.toDouble() ?? 0.0;
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

  Future<int> createMissingPaymentRecordsForPaidOrders(int customerId) async {
    final db = await _dbHelper.database;
    final ordersWithoutPayments = await db.rawQuery(
      '''
      SELECT o.id, o.paid_amount, o.created_at
      FROM orders o
      LEFT JOIN payments p ON p.order_id = o.id
      WHERE o.customer_id = ?
        AND o.paid_amount > 0
      GROUP BY o.id
      HAVING COUNT(p.id) = 0
      ''',
      [customerId],
    );

    var createdCount = 0;
    for (final order in ordersWithoutPayments) {
      final orderId = order['id'] as int?;
      final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0.0;
      if (orderId == null || paidAmount <= 0) continue;

      DateTime paymentDate;
      try {
        paymentDate = DateTime.parse(order['created_at'] as String);
      } catch (_) {
        paymentDate = DateTime.now();
      }

      await createPayment(
        Payment(
          orderId: orderId,
          customerId: customerId,
          amount: paidAmount,
          paymentMethod: Payment.methodCash,
          paymentDate: paymentDate,
          notes: 'Initial deposit',
        ),
      );
      createdCount++;
    }

    return createdCount;
  }
}
