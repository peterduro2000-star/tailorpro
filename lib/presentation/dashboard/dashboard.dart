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
import './widgets/todays_work_widget.dart';

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

  // ==================== CACHED METRICS (STEP 3A) ====================
  List<Order> _overdueOrdersCache = [];
  List<Order> _dueTodayOrdersCache = [];
  List<Order> _dueThisWeekOrdersCache = [];

  int _activeOrdersCache = 0;
  int _unpaidOrdersCache = 0;

  double _totalRevenueCache = 0.0;
  double _totalPaidCache = 0.0;
  double _totalBalanceCache = 0.0;

  int _customersWithBalanceCache = 0;
  int _customersWithActiveOrdersCache = 0;
  // ================================================================

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    // Check if cache is still valid
    if (!forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheDuration) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (_lastLoadTime == null) {
        _lastLoadTime = DateTime.now();
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

        _calculateMetrics(); // ← STEP 3C

        _lastLoadTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      String message = 'Failed to load dashboard. Please try again.';

      final errorText = e.toString().toLowerCase();

      if (errorText.contains('socket') ||
          errorText.contains('network') ||
          errorText.contains('failed host lookup')) {
        message = 'No internet connection. Please check your network.';
      } else if (errorText.contains('timeout')) {
        message = 'Request timed out. Try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint('Error loading dashboard: $e');
    }
  }

  // ==================== METRICS CALCULATION (STEP 3B) ====================
  void _calculateMetrics() {
    _overdueOrdersCache = _allOrders.where((o) => o.isOverdue).toList();
    _dueTodayOrdersCache = _allOrders.where((o) => o.isDueToday).toList();
    _dueThisWeekOrdersCache = _allOrders.where((o) => o.isDueThisWeek).toList();

    _activeOrdersCache =
        _allOrders.where((o) => o.status != Order.statusCollected).length;

    _unpaidOrdersCache = _allOrders.where((o) => o.isUnpaid).length;

    _totalRevenueCache = _allOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    _totalPaidCache = _allOrders.fold(0.0, (sum, o) => sum + o.paidAmount);
    _totalBalanceCache = _totalRevenueCache - _totalPaidCache;

    _customersWithBalanceCache = _allOrders
        .where((o) => o.balance > 0)
        .map((o) => o.customerId)
        .toSet()
        .length;

    _customersWithActiveOrdersCache = _allOrders
        .where((o) => o.status != Order.statusCollected)
        .map((o) => o.customerId)
        .toSet()
        .length;
  }
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TailorPro',
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Dashboard',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications',
              size: 24,
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
            ),
            onPressed: _showDueOrderReminders,
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 24,
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
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
              child: _totalCustomers == 0 && !_isLoading
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRefreshHint(),
                          _buildLastUpdatedTime(),

                          // Quick Stats
                          QuickStatsWidget(
                            totalCustomers: _totalCustomers,
                            customersWithActiveOrders:
                                _customersWithActiveOrdersCache,
                            activeOrders: _activeOrdersCache,
                            overdueOrders: _overdueOrdersCache.length,
                            unpaidOrders: _unpaidOrdersCache,
                          ),

                          SizedBox(height: 3.h),

                          // Today's Work
                          TodaysWorkWidget(
                            overdueOrders: _overdueOrdersCache,
                            dueTodayOrders: _dueTodayOrdersCache,
                            onTapOrder: (order) {
                              Navigator.of(context).pushNamed(
                                '/customer-profile',
                                arguments: order.customerId,
                              );
                            },
                          ),

                          SizedBox(height: 3.h),

                          // Attention Needed
                          AttentionCardWidget(
                            overdueOrders: _overdueOrdersCache,
                            dueTodayOrders: _dueTodayOrdersCache,
                            onViewAll: () {
                              Navigator.of(context).pushNamed('/customer-list');
                            },
                          ),

                          SizedBox(height: 3.h),

                          // This Week Overview
                          WeekOverviewWidget(
                            orders: _dueThisWeekOrdersCache,
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
          await Navigator.of(context).pushNamed('/add-customer');
          _loadDashboardData(forceRefresh: true);
        },
        icon: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color: theme.floatingActionButtonTheme.foregroundColor ??
              theme.colorScheme.onPrimary,
        ),
        label: Text(
          'New Customer',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.floatingActionButtonTheme.foregroundColor ??
                theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================
  // UI BUILDER METHODS (unchanged except financial card)
  // ============================================

  void _showDueOrderReminders() {
    final hasDueOrders = _overdueOrdersCache.isNotEmpty ||
        _dueTodayOrdersCache.isNotEmpty ||
        _dueThisWeekOrdersCache.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.h),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Reminders',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Due orders that need attention',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  if (!hasDueOrders)
                    _buildNoUrgentOrdersState(theme)
                  else ...[
                    _buildReminderSection(
                      theme: theme,
                      title: 'Overdue Orders',
                      orders: _overdueOrdersCache,
                      icon: Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      emptyMessage: 'No overdue orders',
                    ),
                    _buildReminderSection(
                      theme: theme,
                      title: 'Due Today',
                      orders: _dueTodayOrdersCache,
                      icon: Icons.today_outlined,
                      color: theme.colorScheme.primary,
                      emptyMessage: 'No orders due today',
                    ),
                    _buildReminderSection(
                      theme: theme,
                      title: 'Due This Week',
                      orders: _dueThisWeekOrdersCache,
                      icon: Icons.date_range_outlined,
                      color: theme.colorScheme.tertiary,
                      emptyMessage: 'No orders due this week',
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNoUrgentOrdersState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'No urgent orders right now',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Overdue and upcoming deliveries will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection({
    required ThemeData theme,
    required String title,
    required List<Order> orders,
    required IconData icon,
    required Color color,
    required String emptyMessage,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                orders.length.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (orders.isEmpty)
            Text(
              emptyMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...orders.map(
              (order) => _buildReminderOrderItem(
                theme: theme,
                order: order,
                accentColor: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderOrderItem({
    required ThemeData theme,
    required Order order,
    required Color accentColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          '/customer-profile',
          arguments: order.customerId,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Customer #${order.customerId} • ${order.orderNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 0.6.h,
                    children: [
                      _buildReminderChip(
                        theme,
                        Icons.event_outlined,
                        _formatDeliveryDate(order.deliveryDate),
                      ),
                      _buildReminderChip(
                        theme,
                        Icons.assignment_turned_in_outlined,
                        Order.getStatusDisplay(order.status),
                      ),
                      if (order.balance > 0)
                        _buildReminderChip(
                          theme,
                          Icons.account_balance_wallet_outlined,
                          'Balance ${_formatCurrency(order.balance)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeliveryDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(0)}';
  }

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
          Icon(Icons.schedule, size: 12, color: Colors.grey),
          SizedBox(width: 1.w),
          Text(
            'Updated $timeAgo',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          Row(
            children: List.generate(
                2,
                (i) => Expanded(
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                    )),
          ),
          SizedBox(height: 2.h),
          Row(
            children: List.generate(
                2,
                (i) => Expanded(
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
          SizedBox(height: 2.h),
          Container(
            height: 100,
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8.h),
          Icon(Icons.dashboard_outlined, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 3.h),
          Text('Welcome to TailorPro!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Start managing your tailoring business by adding your first customer',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Start:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
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
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
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

    final overdueWithBalance =
        _overdueOrdersCache.where((o) => o.balance > 0).length;

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
              theme.colorScheme.primary.withValues(alpha: 0.8)
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
                Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 24),
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
            if (_customersWithBalanceCache > 0 || overdueWithBalance > 0) ...[
              if (_customersWithBalanceCache > 0)
                _buildFinancialStatRow(
                  context,
                  Icons.people,
                  '$_customersWithBalanceCache customer${_customersWithBalanceCache > 1 ? 's' : ''} owe money',
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

  Widget _buildFinancialStatRow(
      BuildContext context, IconData icon, String text, Color color) {
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
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
