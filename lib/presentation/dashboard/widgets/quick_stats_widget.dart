import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class QuickStatsWidget extends StatelessWidget {
  final int totalCustomers;
  final int customersWithActiveOrders; // ✨ NEW PARAMETER
  final int activeOrders;
  final int overdueOrders;
  final int unpaidOrders;

  const QuickStatsWidget({
    super.key,
    required this.totalCustomers,
    required this.customersWithActiveOrders, // ✨ NEW
    required this.activeOrders,
    required this.overdueOrders,
    required this.unpaidOrders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Row 1: Customers + Active Clients (NEW)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Customers',
                totalCustomers.toString(),
                Icons.people,
                theme.colorScheme.primary,
                onTap: () => Navigator.of(context).pushNamed('/customer-list'),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Active Clients',
                customersWithActiveOrders.toString(),
                Icons.work,
                const Color(0xFF4CAF50), // Green for active work
                onTap: () => Navigator.of(context).pushNamed('/customer-list'),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Row 2: Active Orders + Overdue
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Active Orders',
                activeOrders.toString(),
                Icons.shopping_bag,
                const Color(0xFF2196F3),
                onTap: () => _openOrders(
                  context,
                  filter: 'active',
                  title: 'Active Orders',
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Overdue',
                overdueOrders.toString(),
                Icons.warning,
                theme.colorScheme.error,
                onTap: () => _openOrders(
                  context,
                  filter: 'overdue',
                  title: 'Overdue Orders',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Row 3: Unpaid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Unpaid Orders',
                unpaidOrders.toString(),
                Icons.payment,
                const Color(0xFFFF9800),
                onTap: () => _openOrders(
                  context,
                  filter: 'unpaid',
                  title: 'Unpaid Orders',
                ),
              ),
            ),
            SizedBox(width: 3.w),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 1.h),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrders(
    BuildContext context, {
    required String filter,
    required String title,
  }) {
    Navigator.of(context).pushNamed(
      '/orders-list',
      arguments: {
        'filter': filter,
        'title': title,
      },
    );
  }
}
