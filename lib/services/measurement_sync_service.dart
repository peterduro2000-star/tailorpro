import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/measurement_model.dart';
import '../services/cloud_sync_service.dart';
import '../repositories/measurement_repository.dart';

/// Unified service for saving measurement data to both local and cloud
class MeasurementSyncService {
  final MeasurementRepository localRepo;
  final CloudSyncService cloudSync;
  final String? userId;

  MeasurementSyncService({
    required this.localRepo,
    required this.cloudSync,
    this.userId,
  });

  /// Create measurement in both local and cloud (if user is logged in)
  Future<Measurement> createMeasurement(Measurement measurement) async {
    final localMeasurement = await localRepo.createMeasurement(measurement);

    if (userId != null) {
      try {
        await cloudSync.saveMeasurementToCloud(localMeasurement, userId!);
        print('DEBUG: Measurement synced to cloud');
      } catch (e) {
        print('WARNING: Failed to sync measurement to cloud: $e');
      }
    }

    return localMeasurement;
  }

  /// Update measurement in both local and cloud
  Future<int> updateMeasurement(Measurement measurement) async {
    final result = await localRepo.updateMeasurement(measurement);

    if (userId != null) {
      try {
        await cloudSync.saveMeasurementToCloud(measurement, userId!);
        print('DEBUG: Measurement updated in cloud');
      } catch (e) {
        print('WARNING: Failed to sync updated measurement to cloud: $e');
      }
    }

    return result;
  }

  /// Proxy methods for read operations
  Future<List<Measurement>> getCustomerMeasurements(int customerId) =>
      localRepo.getCustomerMeasurements(customerId);

  Future<Measurement?> getMeasurementById(int id) =>
      localRepo.getMeasurementById(id);

  /// Delete measurement
  Future<int> deleteMeasurement(int id) async {
    final result = await localRepo.deleteMeasurement(id);
    print('DEBUG: Measurement deleted locally');
    return result;
  }
}
