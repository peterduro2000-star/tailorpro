import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/order_model.dart';
import '../../../repositories/customer_repository.dart';

class TodaysWorkWidget extends StatefulWidget {
  final List<Order> overdueOrders;
  final List<Order> dueTodayOrders;
  final void Function(Order order) onTapOrder;
  final int maxItems;

  const TodaysWorkWidget({
    super.key,
    required this.overdueOrders,
    required this.dueTodayOrders,
    required this.onTapOrder,
    this.maxItems = 5,
  });

  @override
  State<TodaysWorkWidget> createState() => _TodaysWorkWidgetState();
}

class _TodaysWorkWidgetState extends State<TodaysWorkWidget> {
  final CustomerRepository _customerRepository = CustomerRepository();
  final Map<int, String> _customerNameCache = {};

  Future<String> _getCustomerName(int customerId) async {
    if (_customerNameCache.containsKey(customerId)) {
      return _customerNameCache[customerId]!;
    }
    
    try {
      final customer = await _customerRepository.getCustomerById(customerId);
      final name = customer?.name ?? 'Unknown';
      _customerNameCache[customerId] = name;
      return name;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayedOverdue = widget.overdueOrders.take(widget.maxItems).toList();
    final displayedDueToday = widget.dueTodayOrders.take(widget.maxItems).toList();

    // Don't show widget if no overdue or due today orders
    if (displayedOverdue.isEmpty && displayedDueToday.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Work',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (widget.overdueOrders.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 1.w),
                      Text(
                        '${widget.overdueOrders.length} Overdue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                SizedBox(width: 4.w),
                if (widget.dueTodayOrders.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 16),
                      SizedBox(width: 1.w),
                      Text(
                        '${widget.dueTodayOrders.length} Due Today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Overdue Orders
        if (displayedOverdue.isNotEmpty) ...[
          Text(
            'OVERDUE',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 1.h),
          ...displayedOverdue.map((order) => _buildOrderItem(context, order, isOverdue: true)).toList(),
          SizedBox(height: 2.h),
        ],

        // Due Today Orders
        if (displayedDueToday.isNotEmpty) ...[
          Text(
            'DUE TODAY',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          ...displayedDueToday.map((order) => _buildOrderItem(context, order, isOverdue: false)).toList(),
        ],

        // View All button if there are more items
        if (displayedOverdue.length < widget.overdueOrders.length ||
            displayedDueToday.length < widget.dueTodayOrders.length) ...[
          SizedBox(height: 2.h),
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to orders list
                Navigator.of(context).pushNamed('/orders-list');
              },
              child: Text('View All Work Items →'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order, {required bool isOverdue}) {
    final theme = Theme.of(context);
    
    return FutureBuilder<String>(
      future: _getCustomerName(order.customerId),
      builder: (context, snapshot) {
        final customerName = snapshot.data ?? 'Loading...';
        
        return InkWell(
          onTap: () => widget.onTapOrder(order),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 0.5.h),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOverdue ? Colors.red.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '$customerName – ${order.orderTitle}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      color: isOverdue ? Colors.red.shade800 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isOverdue ? 'Overdue' : 'Due Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue ? Colors.red : theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}