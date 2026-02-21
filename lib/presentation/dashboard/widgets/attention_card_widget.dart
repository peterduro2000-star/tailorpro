import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/order_model.dart';
import '../../../widgets/custom_icon_widget.dart';

class AttentionCardWidget extends StatelessWidget {
  final List<Order> overdueOrders;
  final List<Order> dueTodayOrders;
  final VoidCallback onViewAll;

  const AttentionCardWidget({
    super.key,
    required this.overdueOrders,
    required this.dueTodayOrders,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAttention = overdueOrders.isNotEmpty || dueTodayOrders.isNotEmpty;

    if (!hasAttention) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: const Color(0xFF4CAF50),
              size: 32,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Caught Up! 🎉',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    'No orders need immediate attention',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Attention Needed',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 1.h),

        // Overdue Orders
        if (overdueOrders.isNotEmpty) ...[
          _buildAttentionItem(
            context,
            '🔴 ${overdueOrders.length} Overdue Order${overdueOrders.length > 1 ? 's' : ''}',
            'Past delivery date',
            theme.colorScheme.error,
            overdueOrders.take(3).toList(),
            'overdue',
          ),
          SizedBox(height: 2.h),
        ],

        // Due Today
        if (dueTodayOrders.isNotEmpty) ...[
          _buildAttentionItem(
            context,
            '🟠 ${dueTodayOrders.length} Due Today',
            'Delivery expected today',
            const Color(0xFFFF5722),
            dueTodayOrders.take(3).toList(),
            'due_today',
          ),
        ],
      ],
    );
  }

  Widget _buildAttentionItem(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    List<Order> orders,
    String filterType,
  ) {
    final theme = Theme.of(context);

    // Clean title for navigation argument (remove emoji)
    final cleanTitle = title.replaceAll(RegExp(r'[🔴🟠]'), '').trim();

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/orders-list',
          arguments: {
            'filter': filterType,
            'title': cleanTitle,
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
            if (orders.isNotEmpty) ...[
              SizedBox(height: 2.h),
              ...orders.map((order) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            order.orderTitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          order.isOverdue
                              ? '${order.daysOverdue}d overdue'
                              : 'Today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}