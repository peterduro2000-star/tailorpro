import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../../widgets/custom_icon_widget.dart';

class OrdersTabWidget extends StatefulWidget {
  final Map<String, dynamic> customer;

  const OrdersTabWidget({
    super.key,
    required this.customer,
  });

  @override
  State<OrdersTabWidget> createState() => _OrdersTabWidgetState();
}

class _OrdersTabWidgetState extends State<OrdersTabWidget> {
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'pending', 'in_progress', 'ready', 'collected'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _orderRepository.getCustomerOrders(
        widget.customer['id'],
      );
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading orders: $e');
    }
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        if (_orders.isNotEmpty) _buildFilterChips(theme),
        
        // Orders list
        Expanded(
          child: _filteredOrders.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', theme),
            SizedBox(width: 2.w),
            _buildFilterChip('Pending', Order.statusPending, theme),
            SizedBox(width: 2.w),
            _buildFilterChip('In Progress', Order.statusInProgress, theme),
            SizedBox(width: 2.w),
            _buildFilterChip('Ready', Order.statusReady, theme),
            SizedBox(width: 2.w),
            _buildFilterChip('Collected', Order.statusCollected, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filterStatus == value;
    final count = value == 'all'
        ? _orders.length
        : _orders.where((o) => o.status == value).length;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'shopping_bag',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            _orders.isEmpty ? 'No Orders Yet' : 'No ${Order.getStatusDisplay(_filterStatus)} Orders',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _orders.isEmpty
                ? 'Tap the + button to create an order'
                : 'Try a different filter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme) {
    final statusColor = Order.getStatusColor(order.status);
    final isOverdue = order.isOverdue;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? theme.colorScheme.error : theme.dividerColor,
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.orderNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          if (isOverdue)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OVERDUE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onError,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        order.itemType ?? 'Order',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    Order.getStatusDisplay(order.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                // Amount & Payment
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        'Total',
                        '₦${order.totalAmount.toStringAsFixed(0)}',
                        Icons.payments,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        'Paid',
                        '₦${order.paidAmount.toStringAsFixed(0)}',
                        Icons.check_circle,
                        valueColor: order.isPaid
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Balance & Due Date
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        'Balance',
                        '₦${order.balance.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        valueColor: order.balance > 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        'Due Date',
                        '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
                        Icons.calendar_today,
                        valueColor: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Notes
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomIconWidget(
                          iconName: 'note_alt',
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 2.h),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(order),
                        icon: CustomIconWidget(
                          iconName: 'update',
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: const Text('Update Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewDetails(order),
                        icon: CustomIconWidget(
                          iconName: 'visibility',
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(Order order) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Order.allStatuses.map((status) {
            return RadioListTile<String>(
              title: Text(Order.getStatusDisplay(status)),
              value: status,
              groupValue: order.status,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != order.status) {
      try {
        await _orderRepository.updateOrderStatus(order.id!, newStatus);
        await _loadOrders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to ${Order.getStatusDisplay(newStatus)}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
  
  void _viewDetails(Order order) {
    // Show order details in a dialog
    showDialog(
      context: context,
      builder: (context) => _OrderDetailsDialog(order: order),
    );
  }
}

// Moved this class OUTSIDE of _OrdersTabWidgetState
class _OrderDetailsDialog extends StatelessWidget {
  final Order order;

  const _OrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(order.orderNumber),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(theme, 'Order Title', order.orderTitle),
            const Divider(),
            _buildDetailRow(theme, 'Status', Order.getStatusDisplay(order.status)),
            if (order.stage != null)
              _buildDetailRow(theme, 'Stage', order.stage!),
            const Divider(),
            _buildDetailRow(theme, 'Total Amount', '₦${order.totalAmount.toStringAsFixed(0)}'),
            _buildDetailRow(theme, 'Paid Amount', '₦${order.paidAmount.toStringAsFixed(0)}'),
            _buildDetailRow(
              theme, 
              'Balance', 
              '₦${order.balance.toStringAsFixed(0)}',
              valueColor: order.balance > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            const Divider(),
            _buildDetailRow(
              theme, 
              'Delivery Date', 
              '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
            ),
            _buildDetailRow(theme, 'Quantity', order.quantity.toString()),
            if (order.itemType != null)
              _buildDetailRow(theme, 'Item Type', order.itemType!),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const Divider(),
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                order.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}