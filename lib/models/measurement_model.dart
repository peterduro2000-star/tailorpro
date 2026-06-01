import 'dart:convert';

class Measurement {
  final int? id;
  final String? remoteId;
  final int customerId;
  final String measurementType;
  final Map<String, double> measurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Measurement({
    this.id,
    this.remoteId,
    required this.customerId,
    required this.measurementType,
    required this.measurements,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remote_id': remoteId,
      'customer_id': customerId,
      'measurement_type': measurementType,
      'measurements': _measurementsToJson(measurements),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as String?,
      customerId: map['customer_id'] as int,
      measurementType: map['measurement_type'] as String,
      measurements: _measurementsFromJson(map['measurements'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert measurements map to JSON string for storage
  static String _measurementsToJson(Map<String, double> measurements) {
    return jsonEncode(measurements);
  }

  // Convert JSON string back to measurements map
  static Map<String, double> _measurementsFromJson(String json) {
    if (json.trim().isEmpty) return {};

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final parsedValue = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
      return MapEntry(key, parsedValue);
    });
  }

  Measurement copyWith({
    int? id,
    String? remoteId,
    int? customerId,
    String? measurementType,
    Map<String, double>? measurements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Measurement(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      customerId: customerId ?? this.customerId,
      measurementType: measurementType ?? this.measurementType,
      measurements: measurements ?? this.measurements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to display format for UI
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'type': measurementType,
      'date': '${createdAt.day}/${createdAt.month}/${createdAt.year}',
      'values': measurements,
    };
  }
}

// Measurement Templates (keep this part the same)
class MeasurementTemplates {
  static Map<String, List<String>> templates = {
    'Shirt': [
      'Neck',
      'Shoulder',
      'Chest',
      'Sleeve Length',
      'Shirt Length',
      'Bicep',
      'Wrist',
    ],
    'Trouser': [
      'Waist',
      'Hip',
      'Thigh',
      'Knee',
      'Trouser Length',
      'Crotch',
      'Bottom',
    ],
    'Dress/Gown': [
      'Bust',
      'Waist',
      'Hip',
      'Shoulder',
      'Sleeve Length',
      'Dress Length',
      'Arm Hole',
    ],
  };

  static List<String> getMeasurementFields(String type) {
    return templates[type] ?? [];
  }

  static List<String> getAllTypes() {
    return templates.keys.toList();
  }
}