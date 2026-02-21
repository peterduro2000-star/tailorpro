import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/order_model.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/attention_card_widget.dart';
import './widgets/week_overview_widget.dart';
import './widgets/quick_stats_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final OrderRepository _orderRepository = OrderRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  List<Order> _allOrders = [];
  int _totalCustomers = 0;
  bool _isLoading = true;
  DateTime? _lastLoadTime;
  static const _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    // Check if cache is still valid
    if (!forceRefresh && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      if (_lastLoadTime == null) {
        _lastLoadTime = DateTime.now(); // SET ON FIRST LOAD
      }
    });

    try {
      // Load data in parallel
      final results = await Future.wait([
        _orderRepository.getAllOrders(),
        _customerRepository.getAllCustomers(),
      ]);

      if (!mounted) return;

      setState(() {
        _allOrders = results[0] as List<Order>;
        _totalCustomers = (results[1] as List).length;
        _lastLoadTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      debugPrint('Error loading dashboard: $e');
    }
  }

  // Calculate metrics
  List<Order> get _overdueOrders =>
      _allOrders.where((o) => o.isOverdue).toList();

  List<Order> get _dueTodayOrders =>
      _allOrders.where((o) => o.isDueToday).toList();

  List<Order> get _dueThisWeekOrders =>
      _allOrders.where((o) => o.isDueThisWeek).toList();

  double get _totalRevenue =>
      _allOrders.fold(0, (sum, order) => sum + order.totalAmount);

  double get _totalPaid =>
      _allOrders.fold(0, (sum, order) => sum + order.paidAmount);

  double get _totalBalance => _totalRevenue - _totalPaid;

  int get _unpaidOrders =>
      _allOrders.where((o) => o.isUnpaid).length;

  int get _activeOrders =>
      _allOrders.where((o) => o.status != Order.statusCollected).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TailorPro', style: theme.appBarTheme.titleTextStyle),
            Text(
              'Dashboard',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
  IconButton(
    icon: CustomIconWidget(
      iconName: 'notifications',
      size: 24,
      color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
    ),
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications coming soon!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  ),

  // ✅ SETTINGS BUTTON
  IconButton(
    icon: Icon(
      Icons.settings,
      size: 24,
      color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
    ),
    onPressed: () {
      Navigator.of(context).pushNamed('/settings');
    },
  ),

  IconButton(
    icon: CustomIconWidget(
      iconName: 'person',
      size: 24,
      color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
    ),
    onPressed: () {
      Navigator.of(context).pushNamed('/customer-list');
    },
  ),
],

      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadDashboardData(forceRefresh: true),
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: _allOrders.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pull to refresh hint
                          _buildRefreshHint(),
                          
                          // Last updated timestamp
                          _buildLastUpdatedTime(),

                          // Quick Stats
                          QuickStatsWidget(
                            totalCustomers: _totalCustomers,
                            activeOrders: _activeOrders,
                            overdueOrders: _overdueOrders.length,
                            unpaidOrders: _unpaidOrders,
                          ),

                          SizedBox(height: 3.h),

                          // Attention Needed
                          AttentionCardWidget(
                            overdueOrders: _overdueOrders,
                            dueTodayOrders: _dueTodayOrders,
                            onViewAll: () {
                              Navigator.of(context).pushNamed('/customer-list');
                            },
                          ),

                          SizedBox(height: 3.h),

                          // This Week Overview
                          WeekOverviewWidget(
                            orders: _dueThisWeekOrders,
                          ),

                          SizedBox(height: 3.h),

                          // Financial Overview Card
                          _buildFinancialOverviewCard(context),

                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/customer-list');
          _loadDashboardData(forceRefresh: true); 
        },
        icon: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color: theme.floatingActionButtonTheme.foregroundColor ?? theme.colorScheme.onPrimary,
        ),
        label: Text(
          'New Customer',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.floatingActionButtonTheme.foregroundColor ?? theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // FIX 1: Improved Last Updated Time Format
  Widget _buildLastUpdatedTime() {
    if (_lastLoadTime == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final diff = now.difference(_lastLoadTime!);
    
    String timeAgo;
    if (diff.inSeconds < 60) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = '${diff.inDays}d ago';
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Colors.grey,
          ),
          SizedBox(width: 1.w),
          Text(
            'Updated $timeAgo',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // FIX 4: Pull to refresh hint
  Widget _buildRefreshHint() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_down, size: 16, color: Colors.grey),
          SizedBox(width: 1.w),
          Text(
            'Pull to refresh',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // FIX 3: Loading Skeleton
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          // Stats skeleton - first row
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 100,
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            )),
          ),
          SizedBox(height: 2.h),
          // Stats skeleton - second row
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 100,
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ),
          SizedBox(height: 3.h),
          // Attention card skeleton
          Container(
            height: 120,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),
          // Week overview skeleton
          Container(
            height: 200,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  // FIX 2: Enhanced Empty State
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8.h),
          Icon(
            Icons.dashboard_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 3.h),
          Text(
            'Welcome to TailorPro!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Start managing your tailoring business by adding your first customer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          
          // Quick start guide
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Start:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildQuickStartItem('1. Add your customers'),
                _buildQuickStartItem('2. Take measurements'),
                _buildQuickStartItem('3. Create orders'),
                _buildQuickStartItem('4. Track payments'),
              ],
            ),
          ),
          
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).pushNamed('/customer-list');
              _loadDashboardData(forceRefresh: true);
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add First Customer'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 2.h,
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildQuickStartItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 2.w),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildFinancialOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    
    // Count customers with balances
    final customersWithBalance = _allOrders
        .where((o) => o.balance > 0)
        .map((o) => o.customerId)
        .toSet()
        .length;
    
    // Count overdue with balance
    final overdueWithBalance = _allOrders
        .where((o) => o.isOverdue && o.balance > 0)
        .length;

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/financial-summary');
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
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
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                SizedBox(width: 2.w),
                Text(
                  'Financial Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 2.h),
            
            if (customersWithBalance > 0 || overdueWithBalance > 0) ...[
              if (customersWithBalance > 0)
                _buildFinancialStatRow(
                  context,
                  Icons.people,
                  '$customersWithBalance customer${customersWithBalance > 1 ? 's' : ''} owe money',
                  Colors.orange,
                ),
              SizedBox(height: 1.h),
              if (overdueWithBalance > 0)
                _buildFinancialStatRow(
                  context,
                  Icons.warning,
                  '$overdueWithBalance overdue payment${overdueWithBalance > 1 ? 's' : ''}',
                  Colors.red.shade300,
                ),
            ] else ...[
              _buildFinancialStatRow(
                context,
                Icons.check_circle,
                'All payments up to date!',
                Colors.green.shade300,
              ),
            ],
            
            SizedBox(height: 2.h),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Full Report',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 1.w),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStatRow(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}