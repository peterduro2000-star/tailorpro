import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/measurement_model.dart';
import '../models/payment_model.dart';
import 'database_helper.dart';

class CloudSyncService {
  final SupabaseClient client;
  final DatabaseHelper dbHelper;

  CloudSyncService({required this.client, required this.dbHelper});

  // --- LOCAL DB HELPERS ---
  Future<Map<String, dynamic>?> _findLocalRow(String table, int id) async {
    final db = await dbHelper.database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> _markLocalRowSynced(String table, int localId, String remoteId) async {
    final db = await dbHelper.database;
    await db.update(
      table,
      {
        'remote_id': remoteId,
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<String?> _ensureCustomerRemoteId(int customerId, String userId) async {
    final row = await _findLocalRow('customers', customerId);
    if (row == null) {
      throw Exception('Local customer not found: $customerId');
    }

    final existingRemoteId = row['remote_id'] as String?;
    if (existingRemoteId != null && existingRemoteId.isNotEmpty) {
      return existingRemoteId;
    }

    return await saveCustomerToCloud(Customer.fromMap(row), userId);
  }

  Future<String?> _ensureMeasurementRemoteId(int measurementId, String userId) async {
    final row = await _findLocalRow('measurements', measurementId);
    if (row == null) {
      throw Exception('Local measurement not found: $measurementId');
    }

    final existingRemoteId = row['remote_id'] as String?;
    if (existingRemoteId != null && existingRemoteId.isNotEmpty) {
      return existingRemoteId;
    }

    return await saveMeasurementToCloud(Measurement.fromMap(row), userId);
  }

  Future<String?> _ensureOrderRemoteId(int orderId, String userId) async {
    final row = await _findLocalRow('orders', orderId);
    if (row == null) {
      throw Exception('Local order not found: $orderId');
    }

    final existingRemoteId = row['remote_id'] as String?;
    if (existingRemoteId != null && existingRemoteId.isNotEmpty) {
      return existingRemoteId;
    }

    return await saveOrderToCloud(Order.fromMap(row), userId);
  }

  Future<String?> _ensurePaymentRemoteId(int paymentId, String userId) async {
    final row = await _findLocalRow('payments', paymentId);
    if (row == null) {
      throw Exception('Local payment not found: $paymentId');
    }

    final existingRemoteId = row['remote_id'] as String?;
    if (existingRemoteId != null && existingRemoteId.isNotEmpty) {
      return existingRemoteId;
    }

    return await savePaymentToCloud(Payment.fromMap(row), userId);
  }

  // --- CUSTOMERS ---
  Future<String?> saveCustomerToCloud(Customer customer, String userId) async {
    try {
      final payload = {
        'user_id': userId,
        'name': customer.name,
        'phone': customer.phone,
        'gender': customer.gender,
        'email': customer.email,
        'notes': customer.notes,
        'created_at': customer.createdAt.toIso8601String(),
        'updated_at': customer.updatedAt.toIso8601String(),
      };
      if (customer.remoteId != null && customer.remoteId!.isNotEmpty) {
        payload['id'] = customer.remoteId;
      }

      final response = await client
          .from('customers')
          .upsert(payload)
          .select()
          .maybeSingle();

      final remoteId = response?['id'] as String?;
      if (remoteId != null && customer.id != null) {
        await _markLocalRowSynced('customers', customer.id!, remoteId);
      }
      print('DEBUG: Customer saved to cloud: ${customer.name}');
      return remoteId;
    } catch (e) {
      print('ERROR: Failed to save customer to cloud: $e');
      throw Exception('Failed to sync customer: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomersFromCloud(String userId) async {
    try {
      final response = await client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => {
                'id': json['id'],
                'user_id': json['user_id'],
                'name': json['name'],
                'phone': json['phone'],
                'gender': json['gender'],
                'email': json['email'],
                'notes': json['notes'],
                'created_at': json['created_at']?.toString(),
                'updated_at': json['updated_at']?.toString(),
              })
          .toList();
    } catch (e) {
      print('ERROR: Failed to fetch customers from cloud: $e');
      return [];
    }
  }

  // --- MEASUREMENTS ---
  Future<String?> saveMeasurementToCloud(Measurement measurement, String userId) async {
    try {
      final customerRemoteId = await _ensureCustomerRemoteId(measurement.customerId, userId);
      final payload = {
        'user_id': userId,
        'customer_id': customerRemoteId,
        'measurement_type': measurement.measurementType,
        'measurements': measurement.measurements,
        'created_at': measurement.createdAt.toIso8601String(),
        'updated_at': measurement.updatedAt.toIso8601String(),
      };
      if (measurement.remoteId != null && measurement.remoteId!.isNotEmpty) {
        payload['id'] = measurement.remoteId;
      }

      final response = await client.from('measurements').upsert(payload).select().maybeSingle();
      final remoteId = response?['id'] as String?;
      if (remoteId != null && measurement.id != null) {
        await _markLocalRowSynced('measurements', measurement.id!, remoteId);
      }
      print('DEBUG: Measurement saved to cloud');
      return remoteId;
    } catch (e) {
      print('ERROR: Failed to save measurement to cloud: $e');
      throw Exception('Failed to sync measurement: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMeasurementsFromCloud(String userId) async {
    try {
      final response = await client
          .from('measurements')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => {
                'id': json['id'],
                'user_id': json['user_id'],
                'customer_id': json['customer_id'],
                'measurement_type': json['measurement_type'],
                'measurements': json['measurements'],
                'created_at': json['created_at']?.toString(),
                'updated_at': json['updated_at']?.toString(),
              })
          .toList();
    } catch (e) {
      print('ERROR: Failed to fetch measurements from cloud: $e');
      return [];
    }
  }

  // --- ORDERS ---
  Future<String?> saveOrderToCloud(Order order, String userId) async {
    try {
      final customerRemoteId = await _ensureCustomerRemoteId(order.customerId, userId);
      String? measurementRemoteId;
      if (order.measurementId != null) {
        measurementRemoteId = await _ensureMeasurementRemoteId(order.measurementId!, userId);
      }

      final payload = {
        'user_id': userId,
        'customer_id': customerRemoteId,
        'order_number': order.orderNumber,
        'order_title': order.orderTitle,
        'status': order.status,
        'stage': order.stage,
        'total_amount': order.totalAmount,
        'paid_amount': order.paidAmount,
        'created_at': order.createdAt.toIso8601String(),
        'delivery_date': order.deliveryDate.toIso8601String(),
        'actual_delivery_date': order.actualDeliveryDate?.toIso8601String(),
        'notes': order.notes,
        'measurement_id': measurementRemoteId,
        'item_type': order.itemType,
        'quantity': order.quantity,
        'fabric_details': order.fabricDetails,
        'updated_at': order.updatedAt.toIso8601String(),
      };
      if (order.remoteId != null && order.remoteId!.isNotEmpty) {
        payload['id'] = order.remoteId;
      }

      final response = await client
          .from('orders')
          .upsert(payload)
          .select()
          .maybeSingle();

      final remoteId = response?['id'] as String?;
      if (remoteId != null && order.id != null) {
        await _markLocalRowSynced('orders', order.id!, remoteId);
      }
      print('DEBUG: Order saved to cloud: ${order.orderNumber}');
      return remoteId;
    } catch (e) {
      print('ERROR: Failed to save order to cloud: $e');
      throw Exception('Failed to sync order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrdersFromCloud(String userId) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => {
                'id': json['id'],
                'user_id': json['user_id'],
                'customer_id': json['customer_id'],
                'order_number': json['order_number'],
                'order_title': json['order_title'],
                'status': json['status'],
                'stage': json['stage'],
                'total_amount': json['total_amount'],
                'paid_amount': json['paid_amount'],
                'created_at': json['created_at']?.toString(),
                'delivery_date': json['delivery_date']?.toString(),
                'actual_delivery_date': json['actual_delivery_date']?.toString(),
                'notes': json['notes'],
                'measurement_id': json['measurement_id'],
                'item_type': json['item_type'],
                'quantity': json['quantity'],
                'fabric_details': json['fabric_details'],
                'updated_at': json['updated_at']?.toString(),
              })
          .toList();
    } catch (e) {
      print('ERROR: Failed to fetch orders from cloud: $e');
      return [];
    }
  }

  // --- PAYMENTS ---
  Future<String?> savePaymentToCloud(Payment payment, String userId) async {
    try {
      final orderRemoteId = await _ensureOrderRemoteId(payment.orderId, userId);
      final customerRemoteId = await _ensureCustomerRemoteId(payment.customerId, userId);

      final payload = {
        'user_id': userId,
        'order_id': orderRemoteId,
        'customer_id': customerRemoteId,
        'amount': payment.amount,
        'payment_method': payment.paymentMethod,
        'payment_date': payment.paymentDate.toIso8601String(),
        'notes': payment.notes,
        'created_at': payment.createdAt.toIso8601String(),
        'updated_at': payment.updatedAt.toIso8601String(),
      };
      if (payment.remoteId != null && payment.remoteId!.isNotEmpty) {
        payload['id'] = payment.remoteId;
      }

      final response = await client.from('payments').upsert(payload).select().maybeSingle();
      final remoteId = response?['id'] as String?;
      if (remoteId != null && payment.id != null) {
        await _markLocalRowSynced('payments', payment.id!, remoteId);
      }
      print('DEBUG: Payment saved to cloud');
      return remoteId;
    } catch (e) {
      print('ERROR: Failed to save payment to cloud: $e');
      throw Exception('Failed to sync payment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentsFromCloud(String userId) async {
    try {
      final response = await client
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => {
                'id': json['id'],
                'user_id': json['user_id'],
                'order_id': json['order_id'],
                'customer_id': json['customer_id'],
                'amount': json['amount'],
                'payment_method': json['payment_method'],
                'payment_date': json['payment_date']?.toString(),
                'notes': json['notes'],
                'created_at': json['created_at']?.toString(),
                'updated_at': json['updated_at']?.toString(),
              })
          .toList();
    } catch (e) {
      print('ERROR: Failed to fetch payments from cloud: $e');
      return [];
    }
  }

  // --- BULK SYNC ---
  Future<void> syncAllDataFromCloud(String userId) async {
    try {
      print('DEBUG: Starting full cloud sync for user: $userId');
      
      final customers = await fetchCustomersFromCloud(userId);
      final measurements = await fetchMeasurementsFromCloud(userId);
      final orders = await fetchOrdersFromCloud(userId);
      final payments = await fetchPaymentsFromCloud(userId);

      print('DEBUG: Fetched ${customers.length} customers, '
          '${measurements.length} measurements, '
          '${orders.length} orders, '
          '${payments.length} payments from cloud');
    } catch (e) {
      print('ERROR: Failed to sync all data from cloud: $e');
    }
  }
}
