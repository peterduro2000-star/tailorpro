import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../services/cloud_sync_service.dart';
import '../repositories/payment_repository.dart';

/// Unified service for saving payment data to both local and cloud
class PaymentSyncService {
  final PaymentRepository localRepo;
  final CloudSyncService cloudSync;
  final String? userId;

  PaymentSyncService({
    required this.localRepo,
    required this.cloudSync,
    this.userId,
  });

  /// Create payment in both local and cloud (if user is logged in)
  Future<Payment> createPayment(Payment payment) async {
    final localPayment = await localRepo.createPayment(payment);

    if (userId != null) {
      try {
        await cloudSync.savePaymentToCloud(localPayment, userId!);
        print('DEBUG: Payment synced to cloud');
      } catch (e) {
        print('WARNING: Failed to sync payment to cloud: $e');
      }
    }

    return localPayment;
  }

  /// Update payment in both local and cloud
  Future<int> updatePayment(Payment payment) async {
    final result = await localRepo.updatePayment(payment);

    if (userId != null) {
      try {
        await cloudSync.savePaymentToCloud(payment, userId!);
        print('DEBUG: Payment updated in cloud');
      } catch (e) {
        print('WARNING: Failed to sync updated payment to cloud: $e');
      }
    }

    return result;
  }

  /// Proxy methods for read operations
  Future<List<Payment>> getOrderPayments(int orderId) =>
      localRepo.getOrderPayments(orderId);

  Future<List<Payment>> getCustomerPayments(int customerId) =>
      localRepo.getCustomerPayments(customerId);

  Future<Payment?> getPaymentById(int id) => localRepo.getPaymentById(id);

  /// Delete payment
  Future<int> deletePayment(int id) async {
    final result = await localRepo.deletePayment(id);
    print('DEBUG: Payment deleted locally');
    return result;
  }
}
