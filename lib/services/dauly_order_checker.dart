import '../models/order.dart';
import 'order_reminder_service.dart';
import 'notification_service.dart';

class DailyOrderChecker {
  static Future<void> checkOrders(List<Order> orders) async {
    for (final order in orders) {
      final type = OrderReminderService.getReminderType(order);
      if (type == null) continue;

      await NotificationService.showNotification(
        id: order.id ?? order.orderNumber.hashCode,
        title: OrderReminderService.getReminderTitle(type),
        body: OrderReminderService.getReminderBody(order, type),
      );
    }
  }
}
