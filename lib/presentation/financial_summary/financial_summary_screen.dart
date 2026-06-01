import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../widgets/custom_icon_widget.dart';

class FinancialSummaryScreen extends StatefulWidget {
  const FinancialSummaryScreen({super.key});

  @override
  State<FinancialSummaryScreen> createState() => _FinancialSummaryScreenState();
}

class _FinancialSummaryScreenState extends State<FinancialSummaryScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  
  List<Order> _allOrders = [];
  Map<int, Customer> _customersMap = {};
  
  bool _isLoading = true;
  bool _showRevenue = false;
  
  double _totalRevenue = 0.0;
  double _totalPaid = 0.0;
  double _totalBalance = 0.0;
  
  List<Map<String, dynamic>> _debtors = [];
  List<Order> _overdueOrders = [];

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    try {
      final orders = await _orderRepository.getAllOrders();
      final customers = await _customerRepository.getAllCustomers();
      
      // Create customer map for quick lookup
      final customersMap = <int, Customer>{};
      for (var customer in customers) {
        customersMap[customer.id!] = customer;
      }
      
      // Calculate totals
      double totalRevenue = 0.0;
      double totalPaid = 0.0;
      
      for (var order in orders) {
        totalRevenue += order.totalAmount;
        totalPaid += order.paidAmount;
      }
      
      // Group by customer and calculate debts
      final debtorMap = <int, Map<String, dynamic>>{};
      
      for (var order in orders) {
        if (order.balance > 0) {
          if (!debtorMap.containsKey(order.customerId)) {
            debtorMap[order.customerId] = {
              'customerId': order.customerId,
              'totalOwed': 0.0,
              'orderCount': 0,
            };
          }
          debtorMap[order.customerId]!['totalOwed'] += order.balance;
          debtorMap[order.customerId]!['orderCount'] += 1;
        }
      }
      
      // Convert to list and sort by amount
      final debtors = debtorMap.values.toList()
        ..sort((a, b) => (b['totalOwed'] as double).compareTo(a['totalOwed'] as double));
      
      // Get overdue orders with balance
      final overdueOrders = orders
          .where((o) => o.isOverdue && o.balance > 0)
          .toList()
        ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
      
      setState(() {
        _allOrders = orders;
        _customersMap = customersMap;
        _totalRevenue = totalRevenue;
        _totalPaid = totalPaid;
        _totalBalance = totalRevenue - totalPaid;
        _debtors = debtors;
        _overdueOrders = overdueOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Summary', style: theme.appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadFinancialData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Overview
                    _buildRevenueCard(theme),
                    
                    SizedBox(height: 3.h),
                    
                    // Top Debtors
                    _buildDebtorsSection(theme),
                    
                    SizedBox(height: 3.h),
                    
                    // Overdue Payments
                    _buildOverdueSection(theme),
                    
                    SizedBox(height: 3.h),
                    
                    // Payment Methods Breakdown
                    _buildPaymentMethodsCard(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showRevenue ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showRevenue = !_showRevenue;
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          if (_showRevenue) ...[
            _buildRevenueRow(theme, 'Total Revenue', _totalRevenue),
            SizedBox(height: 1.h),
            _buildRevenueRow(theme, 'Total Collected', _totalPaid),
            SizedBox(height: 1.h),
            _buildRevenueRow(theme, 'Outstanding Balance', _totalBalance, isBalance: true),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.7), size: 48),
                  SizedBox(height: 1.h),
                  Text(
                    'Tap the eye icon to view',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildRevenueRow(ThemeData theme, String label, double amount, {bool isBalance = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        Text(
          '₦${amount.toStringAsFixed(0)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: isBalance && amount > 0 ? Colors.orange.shade300 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtorsSection(ThemeData theme) {
    if (_debtors.isEmpty) {
      return _buildEmptyCard(theme, 'No Outstanding Debts', 'All customers have paid in full!');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Debtors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_debtors.length} customer${_debtors.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 2.h),
        
        ..._debtors.take(10).map((debtor) {
          final customer = _customersMap[debtor['customerId']];
          if (customer == null) return const SizedBox.shrink();
          
          return _buildDebtorCard(theme, customer, debtor['totalOwed'], debtor['orderCount']);
        }).toList(),
        
        if (_debtors.length > 10) ...[
          SizedBox(height: 2.h),
          Center(
            child: Text(
              'Showing top 10 of ${_debtors.length} debtors',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDebtorCard(ThemeData theme, Customer customer, double amount, int orderCount) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                customer.name[0].toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 3.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$orderCount order${orderCount > 1 ? 's' : ''} pending',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${amount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _makePhoneCall(customer.phone),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    icon: Icon(Icons.message, size: 20, color: Colors.green),
                    onPressed: () => _openWhatsApp(customer.phone, customer.name, amount),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueSection(ThemeData theme) {
    if (_overdueOrders.isEmpty) {
      return _buildEmptyCard(theme, 'No Overdue Payments', 'All deliveries are on schedule!');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overdue Payments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_overdueOrders.length} order${_overdueOrders.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 2.h),
        
        ..._overdueOrders.take(5).map((order) {
          final customer = _customersMap[order.customerId];
          if (customer == null) return const SizedBox.shrink();
          
          return _buildOverdueCard(theme, order, customer);
        }).toList(),
        
        if (_overdueOrders.length > 5) ...[
          SizedBox(height: 2.h),
          Center(
            child: Text(
              'Showing 5 of ${_overdueOrders.length} overdue orders',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOverdueCard(ThemeData theme, Order order, Customer customer) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${order.daysOverdue} day${order.daysOverdue > 1 ? 's' : ''} overdue',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 1.h),
          
          Text(
            customer.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 0.5.h),
          
          Text(
            order.orderTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: 1.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance: ₦${order.balance.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone, size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _makePhoneCall(customer.phone),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    icon: Icon(Icons.message, size: 20, color: Colors.green),
                    onPressed: () => _openWhatsApp(customer.phone, customer.name, order.balance),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard(ThemeData theme) {
    // Calculate payment method breakdown
    int cashCount = 0;
    int transferCount = 0;
    
    // This is a placeholder - you'd need to fetch actual payment records
    // For now, showing based on orders
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Insights',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInsightRow(theme, 'Total Orders', _allOrders.length.toString()),
          _buildInsightRow(theme, 'Paid in Full', _allOrders.where((o) => o.isPaid).length.toString()),
          _buildInsightRow(theme, 'Partial Payment', _allOrders.where((o) => o.isPartPaid).length.toString()),
          _buildInsightRow(theme, 'Unpaid', _allOrders.where((o) => o.isUnpaid).length.toString()),
        ],
      ),
    );
  }

  Widget _buildInsightRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String customerName, double amount) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String message = Uri.encodeComponent(
      'Hello $customerName, this is a friendly reminder about your outstanding balance of ₦${amount.toStringAsFixed(0)}. Please contact us at your earliest convenience. Thank you!',
    );
    
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}