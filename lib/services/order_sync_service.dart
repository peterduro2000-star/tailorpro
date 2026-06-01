import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../services/cloud_sync_service.dart';
import '../repositories/order_repository.dart';

/// Unified service for saving order data to both local and cloud
class OrderSyncService {
  final OrderRepository localRepo;
  final CloudSyncService cloudSync;
  final String? userId;

  OrderSyncService({
    required this.localRepo,
    required this.cloudSync,
    this.userId,
  });

  /// Create order in both local and cloud (if user is logged in)
  Future<Order> createOrder(Order order) async {
    final localOrder = await localRepo.createOrder(order);

    if (userId != null) {
      try {
        await cloudSync.saveOrderToCloud(localOrder, userId!);
        print('DEBUG: Order synced to cloud: ${localOrder.orderNumber}');
      } catch (e) {
        print('WARNING: Failed to sync order to cloud: $e');
      }
    }

    return localOrder;
  }

  /// Update order in both local and cloud
  Future<int> updateOrder(Order order) async {
    final result = await localRepo.updateOrder(order);

    if (userId != null) {
      try {
        await cloudSync.saveOrderToCloud(order, userId!);
        print('DEBUG: Order updated in cloud: ${order.orderNumber}');
      } catch (e) {
        print('WARNING: Failed to sync updated order to cloud: $e');
      }
    }

    return result;
  }

  /// Proxy methods for read operations
  Future<List<Order>> getAllOrders() => localRepo.getAllOrders();

  Future<Order?> getOrderById(int id) => localRepo.getOrderById(id);

  Future<List<Order>> getOrdersByCustomerId(int customerId) =>
      localRepo.getCustomerOrders(customerId);

  /// Delete order
  Future<int> deleteOrder(int id) async {
    final result = await localRepo.deleteOrder(id);
    print('DEBUG: Order deleted locally');
    return result;
  }
}
