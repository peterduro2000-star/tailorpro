import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../services/cloud_sync_service.dart';
import '../models/customer_model.dart';
import '../models/measurement_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';

class DataSyncService {
  final CloudSyncService cloudSyncService;
  final DatabaseHelper dbHelper;

  DataSyncService({
    required this.cloudSyncService,
    required this.dbHelper,
  });

  /// Sync all data from cloud to local database
  Future<void> syncCloudToLocal(String userId) async {
    try {
      print('DEBUG: Starting cloud to local sync for user: $userId');
      
      final db = await dbHelper.database;

      final cloudCustomers = await cloudSyncService.fetchCustomersFromCloud(userId);
      final cloudMeasurements = await cloudSyncService.fetchMeasurementsFromCloud(userId);
      final cloudOrders = await cloudSyncService.fetchOrdersFromCloud(userId);
      final cloudPayments = await cloudSyncService.fetchPaymentsFromCloud(userId);

      final customerIdMap = <String, int>{};
      final measurementIdMap = <String, int>{};
      final orderIdMap = <String, int>{};

      for (final customer in cloudCustomers) {
        final localId = await db.insert(
          'customers',
          {
            'remote_id': customer['id'],
            'user_id': userId,
            'name': customer['name'],
            'phone': customer['phone'],
            'gender': customer['gender'],
            'email': customer['email'],
            'notes': customer['notes'],
            'created_at': customer['created_at']?.toString(),
            'updated_at': customer['updated_at']?.toString(),
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        customerIdMap[customer['id'] as String] = localId;
      }
      print('DEBUG: Synced ${cloudCustomers.length} customers to local');

      for (final measurement in cloudMeasurements) {
        final remoteCustomerId = measurement['customer_id'] as String?;
        final localCustomerId = remoteCustomerId == null ? null : customerIdMap[remoteCustomerId];
        if (localCustomerId == null) continue;

        final localId = await db.insert(
          'measurements',
          {
            'remote_id': measurement['id'],
            'user_id': userId,
            'customer_id': localCustomerId,
            'measurement_type': measurement['measurement_type'],
            'measurements': jsonEncode(measurement['measurements']),
            'created_at': measurement['created_at']?.toString(),
            'updated_at': measurement['updated_at']?.toString(),
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        measurementIdMap[measurement['id'] as String] = localId;
      }
      print('DEBUG: Synced ${cloudMeasurements.length} measurements to local');

      for (final order in cloudOrders) {
        final remoteCustomerId = order['customer_id'] as String?;
        final localCustomerId = remoteCustomerId == null ? null : customerIdMap[remoteCustomerId];
        if (localCustomerId == null) continue;

        final remoteMeasurementId = order['measurement_id'] as String?;
        final localMeasurementId = remoteMeasurementId == null
            ? null
            : measurementIdMap[remoteMeasurementId];

        final localId = await db.insert(
          'orders',
          {
            'remote_id': order['id'],
            'user_id': userId,
            'customer_id': localCustomerId,
            'order_number': order['order_number'],
            'order_title': order['order_title'],
            'status': order['status'],
            'stage': order['stage'],
            'total_amount': order['total_amount'],
            'paid_amount': order['paid_amount'],
            'created_at': order['created_at']?.toString(),
            'delivery_date': order['delivery_date']?.toString(),
            'actual_delivery_date': order['actual_delivery_date']?.toString(),
            'notes': order['notes'],
            'measurement_id': localMeasurementId,
            'item_type': order['item_type'],
            'quantity': order['quantity'],
            'fabric_details': order['fabric_details'],
            'updated_at': order['updated_at']?.toString(),
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        orderIdMap[order['id'] as String] = localId;
      }
      print('DEBUG: Synced ${cloudOrders.length} orders to local');

      for (final payment in cloudPayments) {
        final remoteOrderId = payment['order_id'] as String?;
        final localOrderId = remoteOrderId == null ? null : orderIdMap[remoteOrderId];
        final remoteCustomerId = payment['customer_id'] as String?;
        final localCustomerId = remoteCustomerId == null ? null : customerIdMap[remoteCustomerId];
        if (localOrderId == null || localCustomerId == null) continue;

        await db.insert(
          'payments',
          {
            'remote_id': payment['id'],
            'user_id': userId,
            'order_id': localOrderId,
            'customer_id': localCustomerId,
            'amount': payment['amount'],
            'payment_method': payment['payment_method'],
            'payment_date': payment['payment_date']?.toString(),
            'notes': payment['notes'],
            'created_at': payment['created_at']?.toString(),
            'updated_at': payment['updated_at']?.toString(),
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      print('DEBUG: Synced ${cloudPayments.length} payments to local');
      
      print('DEBUG: Cloud to local sync completed successfully');
    } catch (e) {
      print('ERROR: Failed to sync cloud data to local: $e');
      rethrow;
    }
  }

  /// Push local changes to cloud
  Future<void> pushLocalToCloud(String userId) async {
    try {
      print('DEBUG: Starting local to cloud push for user: $userId');
      
      final db = await dbHelper.database;

      final customers = await db.query(
        'customers',
        where: 'user_id = ? AND sync_status != ?',
        whereArgs: [userId, 'synced'],
      );

      for (final customer in customers) {
        try {
          final model = Customer.fromMap(customer);
          await cloudSyncService.saveCustomerToCloud(model, userId);
          await db.update(
            'customers',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [customer['id']],
          );
        } catch (e) {
          print('WARNING: Failed to sync customer ${customer['id']}: $e');
        }
      }
      print('DEBUG: Pushed ${customers.length} customers to cloud');

      print('DEBUG: Local to cloud push completed');
    } catch (e) {
      print('ERROR: Failed to push local data to cloud: $e');
      rethrow;
    }
  }
}
