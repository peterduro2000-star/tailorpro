import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/payment_model.dart';
import '../../../models/order_model.dart';
import '../../../repositories/payment_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../widgets/custom_icon_widget.dart';
import './record_payment_dialog.dart';

class PaymentsTabWidget extends StatefulWidget {
  final Map<String, dynamic> customer;

  const PaymentsTabWidget({
    super.key,
    required this.customer,
  });

  @override
  State<PaymentsTabWidget> createState() => _PaymentsTabWidgetState();
}

class _PaymentsTabWidgetState extends State<PaymentsTabWidget> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final OrderRepository _orderRepository = OrderRepository();
  
  List<Payment> _payments = [];
  List<Order> _customerOrders = [];
  bool _isLoading = true;

  double _totalPaid = 0.0;
  double _totalOrders = 0.0;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _paymentRepository.getCustomerPayments(widget.customer['id']);
      final orders = await _orderRepository.getCustomerOrders(widget.customer['id']);
      
      final totalPaid = await _paymentRepository.getCustomerTotalPaid(widget.customer['id']);
      final totalOrders = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
      
      setState(() {
        _payments = payments;
        _customerOrders = orders;
        _totalPaid = totalPaid;
        _totalOrders = totalOrders;
        _balance = totalOrders - totalPaid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading payments: $e');
    }
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
        // Payment Summary Card
        _buildSummaryCard(theme),
        
        // Payment List
        Expanded(
          child: _payments.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      final order = _customerOrders.firstWhere(
                        (o) => o.id == payment.orderId,
                        orElse: () => Order(
                          customerId: widget.customer['id'],
                          orderNumber: 'Unknown',
                          orderTitle: 'Deleted Order',
                          status: Order.statusPending,
                          totalAmount: 0,
                          deliveryDate: DateTime.now(),
                        ),
                      );
                      return _buildPaymentCard(payment, order, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final progress = _totalOrders > 0 ? _totalPaid / _totalOrders : 0.0;
    
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Amounts
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Orders Total',
                  '₦${_totalOrders.toStringAsFixed(0)}',
                  Icons.shopping_bag,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Amount Paid',
                  '₦${_totalPaid.toStringAsFixed(0)}',
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 1.h),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Balance',
                  '₦${_balance.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  color: _balance > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  theme,
                  'Payments',
                  _payments.length.toString(),
                  Icons.receipt,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Record Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _recordPayment,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 1.w),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'No Payments Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tap "Record Payment" to add a payment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, Order order, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Payment method icon
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              payment.paymentMethod == Payment.methodCash
                  ? Icons.money
                  : Icons.account_balance,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          
          SizedBox(width: 3.w),
          
          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₦${payment.amount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Payment.getMethodDisplay(payment.paymentMethod),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  order.orderNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Date and actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                onPressed: () => _editPayment(payment, order),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RecordPaymentDialog(
        customer: widget.customer,
        customerOrders: _customerOrders,
      ),
    );
    
    if (result == true) {
      _loadPayments(); // Refresh payments list
    }
  }

  Future<void> _editPayment(Payment payment, Order order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RecordPaymentDialog(
        customer: widget.customer,
        customerOrders: _customerOrders,
        paymentToEdit: payment,
      ),
    );
    
    if (result == true) {
      _loadPayments(); // Refresh payments list
    }
  }
}