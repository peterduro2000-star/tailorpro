import 'package:flutter/material.dart';

class Order {
  final int? id;
  final int customerId;
  final String orderNumber;
  final String orderTitle; // NEW: e.g., "Wedding Gown", "Native Shirt"
  final String status;
  final String? stage; // NEW: Pending, In Progress, Ready for Fitting, Ready, Collected
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final DateTime deliveryDate; // RENAMED from dueDate - more clear
  final DateTime? actualDeliveryDate; // NEW: When actually collected
  final String? notes;
  final int? measurementId;
  final String? itemType;
  final int quantity;
  final String? fabricDetails; // NEW
  final DateTime updatedAt;

  Order({
    this.id,
    required this.customerId,
    required this.orderNumber,
    required this.orderTitle,
    required this.status,
    this.stage,
    required this.totalAmount,
    this.paidAmount = 0.0,
    DateTime? createdAt,
    required this.deliveryDate,
    this.actualDeliveryDate,
    this.notes,
    this.measurementId,
    this.itemType,
    this.quantity = 1,
    this.fabricDetails,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculated properties
  double get balance => totalAmount - paidAmount;
  bool get isPaid => paidAmount >= totalAmount;
  bool get isPartPaid => paidAmount > 0 && paidAmount < totalAmount;
  bool get isUnpaid => paidAmount == 0;
  
  // Due date calculations
  bool get isOverdue {
    if (status == statusCollected) return false;
    return DateTime.now().isAfter(deliveryDate);
  }
  
  bool get isDueToday {
    final today = DateTime.now();
    return deliveryDate.year == today.year &&
           deliveryDate.month == today.month &&
           deliveryDate.day == today.day &&
           status != statusCollected;
  }
  
  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return deliveryDate.year == tomorrow.year &&
           deliveryDate.month == tomorrow.month &&
           deliveryDate.day == tomorrow.day &&
           status != statusCollected;
  }
  
  bool get isDueSoon {
    if (status == statusCollected) return false;
    final daysUntilDue = deliveryDate.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 3;
  }
  
  bool get isDueThisWeek {
    if (status == statusCollected) return false;
    final daysUntilDue = deliveryDate.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }
  
  int get daysUntilDue {
    return deliveryDate.difference(DateTime.now()).inDays;
  }
  
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(deliveryDate).inDays;
  }

  // Payment status helpers
  String get paymentStatus {
    if (isPaid) return 'Paid';
    if (isPartPaid) return 'Part Payment';
    return 'Unpaid';
  }
  
  Color get paymentStatusColor {
    if (isPaid) return const Color(0xFF4CAF50); // Green
    if (isPartPaid) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_number': orderNumber,
      'order_title': orderTitle,
      'status': status,
      'stage': stage,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'created_at': createdAt.toIso8601String(),
      'delivery_date': deliveryDate.toIso8601String(),
      'actual_delivery_date': actualDeliveryDate?.toIso8601String(),
      'notes': notes,
      'measurement_id': measurementId,
      'item_type': itemType,
      'quantity': quantity,
      'fabric_details': fabricDetails,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      orderNumber: map['order_number'] as String,
      orderTitle: map['order_title'] as String,
      status: map['status'] as String,
      stage: map['stage'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      deliveryDate: DateTime.parse(map['delivery_date'] as String),
      actualDeliveryDate: map['actual_delivery_date'] != null
          ? DateTime.parse(map['actual_delivery_date'] as String)
          : null,
      notes: map['notes'] as String?,
      measurementId: map['measurement_id'] as int?,
      itemType: map['item_type'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      fabricDetails: map['fabric_details'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Order copyWith({
    int? id,
    int? customerId,
    String? orderNumber,
    String? orderTitle,
    String? status,
    String? stage,
    double? totalAmount,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? deliveryDate,
    DateTime? actualDeliveryDate,
    String? notes,
    int? measurementId,
    String? itemType,
    int? quantity,
    String? fabricDetails,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderTitle: orderTitle ?? this.orderTitle,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      notes: notes ?? this.notes,
      measurementId: measurementId ?? this.measurementId,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      fabricDetails: fabricDetails ?? this.fabricDetails,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'order_title': orderTitle,
      'status': status,
      'stage': stage,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance': balance,
      'delivery_date': '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
      'item_type': itemType ?? 'Order',
      'quantity': quantity,
      'is_paid': isPaid,
      'is_overdue': isOverdue,
      'payment_status': paymentStatus,
    };
  }

  // Generate unique order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'ORD-$timestamp';
  }

  // Status constants
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusReady = 'ready';
  static const String statusCollected = 'collected';

  static List<String> get allStatuses => [
        statusPending,
        statusInProgress,
        statusReady,
        statusCollected,
      ];

  // Stage constants (NEW)
  static const String stagePending = 'Pending';
  static const String stageInProgress = 'In Progress';
  static const String stageReadyForFitting = 'Ready for Fitting';
  static const String stageReady = 'Ready';
  static const String stageCollected = 'Collected';

  static List<String> get allStages => [
        stagePending,
        stageInProgress,
        stageReadyForFitting,
        stageReady,
        stageCollected,
      ];

  static String getStatusDisplay(String status) {
    switch (status) {
      case statusPending:
        return 'Pending';
      case statusInProgress:
        return 'In Progress';
      case statusReady:
        return 'Ready';
      case statusCollected:
        return 'Collected';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case statusPending:
        return const Color(0xFFFF9800); // Orange
      case statusInProgress:
        return const Color(0xFF2196F3); // Blue
      case statusReady:
        return const Color(0xFF4CAF50); // Green
      case statusCollected:
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }
  
  // Due status for UI
  String get dueStatus {
    if (status == statusCollected) return 'Collected';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due Today';
    if (isDueTomorrow) return 'Due Tomorrow';
    if (isDueSoon) return 'Due Soon';
    if (isDueThisWeek) return 'This Week';
    return 'Upcoming';
  }
  
  Color get dueStatusColor {
    if (status == statusCollected) return const Color(0xFF9E9E9E);
    if (isOverdue) return const Color(0xFFF44336); // Red
    if (isDueToday) return const Color(0xFFFF5722); // Deep Orange
    if (isDueTomorrow) return const Color(0xFFFF9800); // Orange
    if (isDueSoon) return const Color(0xFFFFC107); // Amber
    if (isDueThisWeek) return const Color(0xFF4CAF50); // Green
    return const Color(0xFF2196F3); // Blue
  }
}