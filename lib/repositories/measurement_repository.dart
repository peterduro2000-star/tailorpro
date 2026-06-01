import 'package:sqflite/sqflite.dart';
import '../models/measurement_model.dart';
import '../services/database_helper.dart';

class MeasurementRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  Future<Measurement> createMeasurement(Measurement measurement) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return measurement.copyWith(id: id);
  }

  // Get all measurements for a customer
  Future<List<Measurement>> getCustomerMeasurements(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'measurements',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  // Get single measurement
  Future<Measurement?> getMeasurementById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'measurements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Measurement.fromMap(maps.first);
  }

  // Get latest measurement of a specific type for a customer
  Future<Measurement?> getLatestMeasurement(
    int customerId,
    String measurementType,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'measurements',
      where: 'customer_id = ? AND measurement_type = ?',
      whereArgs: [customerId, measurementType],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Measurement.fromMap(maps.first);
  }

  // Update
  Future<int> updateMeasurement(Measurement measurement) async {
    final db = await _dbHelper.database;
    return await db.update(
      'measurements',
      measurement.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  // Delete
  Future<int> deleteMeasurement(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get measurement count for customer
  Future<int> getCustomerMeasurementCount(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM measurements WHERE customer_id = ?',
      [customerId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get all measurement types for a customer
  Future<List<String>> getCustomerMeasurementTypes(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'measurements',
      columns: ['measurement_type'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      distinct: true,
    );
    return maps.map((map) => map['measurement_type'] as String).toList();
  }
}