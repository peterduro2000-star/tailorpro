class Customer {
  final int? id;
  final String name;
  final String phone;
  final String gender;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.gender,
    this.email,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'email': email,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      gender: map['gender'] as String,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? gender,
    String? email,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for widget compatibility
  Map<String, dynamic> toDisplayMap({int pendingOrders = 0}) {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'email': email,
      'notes': notes,
      'pendingOrders': pendingOrders,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}