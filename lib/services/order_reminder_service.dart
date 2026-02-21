import '../models/order.dart';

enum OrderReminderType {
  dueSoon,
  dueTomorrow,
  dueToday,
  overdue,
}

class OrderReminderService {
  static OrderReminderType? getReminderType(Order order) {
    if (order.status == Order.statusCollected) return null;

    final today = DateTime.now();
    final dueDate = DateTime(
      order.dueDate.year,
      order.dueDate.month,
      order.dueDate.day,
    );

    final now = DateTime(today.year, today.month, today.day);
    final daysLeft = dueDate.difference(now).inDays;

    if (daysLeft < 0) return OrderReminderType.overdue;
    if (daysLeft == 0) return OrderReminderType.dueToday;
    if (daysLeft == 1) return OrderReminderType.dueTomorrow;
    if (daysLeft <= 3) return OrderReminderType.dueSoon;

    return null;
  }

  static String getReminderTitle(OrderReminderType type) {
    switch (type) {
      case OrderReminderType.dueSoon:
        return '✂️ Order Due Soon';
      case OrderReminderType.dueTomorrow:
        return '⚠️ Order Due Tomorrow';
      case OrderReminderType.dueToday:
        return '🚨 Order Due Today';
      case OrderReminderType.overdue:
        return '❌ Overdue Order';
    }
  }

  static String getReminderBody(Order order, OrderReminderType type) {
    switch (type) {
      case OrderReminderType.dueSoon:
        return 'Order ${order.orderNumber} is due in 3 days';
      case OrderReminderType.dueTomorrow:
        return 'Order ${order.orderNumber} is due tomorrow';
      case OrderReminderType.dueToday:
        return 'Order ${order.orderNumber} is due TODAY';
      case OrderReminderType.overdue:
        return 'Order ${order.orderNumber} is OVERDUE';
    }
  }
}
