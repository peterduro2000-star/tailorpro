import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/order_model.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/custom_icon_widget.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filterType = 'all';
  String _title = 'All Orders';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      setState(() {
        _filterType = args['filter'] ?? 'all';
        _title = args['title'] ?? 'All Orders';
      });
    }

    try {
      final allOrders = await _orderRepository.getAllOrders();
      
      List<Order> filteredOrders;
      
      switch (_filterType) {
        case 'overdue':
          filteredOrders = allOrders.where((o) => o.isOverdue).toList();
          break;
        case 'due_today':
          filteredOrders = allOrders.where((o) => o.isDueToday).toList();
          break;
        case 'due_tomorrow':
          filteredOrders = allOrders.where((o) => o.isDueTomorrow).toList();
          break;
        case 'due_soon':
          filteredOrders = allOrders.where((o) => o.isDueSoon).toList();
          break;
        case 'due_this_week':
          filteredOrders = allOrders.where((o) => o.isDueThisWeek).toList();
          break;
        default:
          filteredOrders = allOrders;
      }

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: theme.appBarTheme.titleTextStyle),
            Text(
              '${_orders.length} order${_orders.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _orders.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'No Orders Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'No orders match this filter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.isOverdue 
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: order.dueStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: order.dueStatusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  order.dueStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: order.dueStatusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 1.h),
          
          // Order title
          Text(
            order.orderTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 1.h),
          
          // Details
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                '${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}',
                style: theme.textTheme.bodySmall,
              ),
              SizedBox(width: 4.w),
              Icon(Icons.shopping_bag, size: 16, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(width: 1.w),
              Text(
                'Qty: ${order.quantity}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          
          SizedBox(height: 1.h),
          
          // Payment info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ₦${order.totalAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Paid: ₦${order.paidAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (order.balance > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Balance: ₦${order.balance.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          if (order.isOverdue) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: theme.colorScheme.error),
                  SizedBox(width: 2.w),
                  Text(
                    '${order.daysOverdue} day${order.daysOverdue > 1 ? 's' : ''} overdue',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}