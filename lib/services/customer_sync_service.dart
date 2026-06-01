import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../services/database_helper.dart';
import '../services/cloud_sync_service.dart';
import '../repositories/customer_repository.dart';

/// Unified service for saving customer data to both local and cloud
class CustomerSyncService {
  final CustomerRepository localRepo;
  final CloudSyncService cloudSync;
  final String? userId;

  CustomerSyncService({
    required this.localRepo,
    required this.cloudSync,
    this.userId,
  });

  /// Create customer in both local and cloud (if user is logged in)
  Future<Customer> createCustomer(Customer customer) async {
    // Save to local first
    final localCustomer = await localRepo.createCustomer(customer);

    // If user is logged in, also save to cloud
    if (userId != null) {
      try {
        await cloudSync.saveCustomerToCloud(localCustomer, userId!);
        print('DEBUG: Customer synced to cloud: ${customer.name}');
      } catch (e) {
        print('WARNING: Failed to sync customer to cloud: $e');
        // Continue even if cloud save fails - data is saved locally
      }
    }

    return localCustomer;
  }

  /// Update customer in both local and cloud
  Future<int> updateCustomer(Customer customer) async {
    // Update local
    final result = await localRepo.updateCustomer(customer);

    // Update cloud if user is logged in
    if (userId != null) {
      try {
        await cloudSync.saveCustomerToCloud(customer, userId!);
        print('DEBUG: Customer updated in cloud: ${customer.name}');
      } catch (e) {
        print('WARNING: Failed to sync updated customer to cloud: $e');
      }
    }

    return result;
  }

  /// Proxy methods for read operations
  Future<List<Customer>> getAllCustomers() => localRepo.getAllCustomers();

  Future<Customer?> getCustomerById(int id) => localRepo.getCustomerById(id);

  Future<List<Customer>> searchCustomers(String query) =>
      localRepo.searchCustomers(query);

  Future<List<Map<String, dynamic>>> getAllCustomersWithOrderCounts() =>
      localRepo.getAllCustomersWithOrderCounts();

  Future<Map<String, dynamic>> getCustomerWithOrderCount(int customerId) =>
      localRepo.getCustomerWithOrderCount(customerId);

  /// Delete customer from both local and cloud
  Future<int> deleteCustomer(int id) async {
    // Delete local first
    final result = await localRepo.deleteCustomer(id);

    // Delete from cloud if needed (would need to implement in cloud service)
    if (userId != null) {
      print('DEBUG: Customer deleted locally - cloud deletion would need to be implemented');
    }

    return result;
  }
}
