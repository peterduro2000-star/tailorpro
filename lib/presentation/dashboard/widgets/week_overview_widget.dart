import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/order_model.dart';

class WeekOverviewWidget extends StatelessWidget {
  final List<Order> orders;

  const WeekOverviewWidget({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekData = _getWeekData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: weekData.map((day) {
              return _buildDayItem(context, day);
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeekData() {
    final now = DateTime.now();
    final weekDays = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayOrders = orders.where((order) {
        return order.deliveryDate.year == date.year &&
            order.deliveryDate.month == date.month &&
            order.deliveryDate.day == date.day;
      }).toList();

      weekDays.add({
        'date': date,
        'orders': dayOrders,
        'isToday': i == 0,
      });
    }

    return weekDays;
  }

  Widget _buildDayItem(BuildContext context, Map<String, dynamic> dayData) {
    final theme = Theme.of(context);
    final date = dayData['date'] as DateTime;
    final orders = dayData['orders'] as List<Order>;
    final isToday = dayData['isToday'] as bool;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = isToday ? 'Today' : dayNames[date.weekday - 1];
    final dateStr = '${date.day}/${date.month}';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Order count badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: orders.isEmpty
                  ? theme.colorScheme.surfaceContainerHighest
                  : isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${orders.length} order${orders.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: orders.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),

          const Spacer(),

          // Order titles (first 2)
          if (orders.isNotEmpty)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: orders.take(2).map((order) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Text(
                      order.orderTitle,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}