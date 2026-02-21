class Payment {
  final int? id;
  final int orderId;
  final int customerId;
  final double amount;
  final String paymentMethod; // 'cash' or 'transfer'
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    DateTime? paymentDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : paymentDate = paymentDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      customerId: map['customer_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Payment copyWith({
    int? id,
    int? orderId,
    int? customerId,
    double? amount,
    String? paymentMethod,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
      'notes': notes,
    };
  }

  // Payment method constants
  static const String methodCash = 'cash';
  static const String methodTransfer = 'transfer';

  static List<String> get allMethods => [methodCash, methodTransfer];

  static String getMethodDisplay(String method) {
    switch (method) {
      case methodCash:
        return 'Cash';
      case methodTransfer:
        return 'Transfer';
      default:
        return method;
    }
  }
}