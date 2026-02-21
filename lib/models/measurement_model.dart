class Measurement {
  final int? id;
  final int customerId;
  final String measurementType;
  final Map<String, double> measurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Measurement({
    this.id,
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
      customerId: map['customer_id'] as int,
      measurementType: map['measurement_type'] as String,
      measurements: _measurementsFromJson(map['measurements'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert measurements map to JSON string for storage
  static String _measurementsToJson(Map<String, double> measurements) {
    final Map<String, dynamic> jsonMap = {};
    measurements.forEach((key, value) {
      jsonMap[key] = value;
    });
    return jsonMap.toString();
  }

  // Convert JSON string back to measurements map
  static Map<String, double> _measurementsFromJson(String json) {
    final cleanJson = json.replaceAll('{', '').replaceAll('}', '');
    final Map<String, double> result = {};
    
    if (cleanJson.trim().isEmpty) return result;
    
    final pairs = cleanJson.split(',');
    for (final pair in pairs) {
      final parts = pair.trim().split(':');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = double.tryParse(parts[1].trim()) ?? 0.0;
        result[key] = value;
      }
    }
    return result;
  }

  Measurement copyWith({
    int? id,
    int? customerId,
    String? measurementType,
    Map<String, double>? measurements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Measurement(
      id: id ?? this.id,
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