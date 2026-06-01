import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PricingSectionWidget extends StatelessWidget {
  final TextEditingController totalAmountController;
  final TextEditingController advancePaymentController;
  final String? pricingError;
  final double currentBalance;
  final VoidCallback onCalculate;

  const PricingSectionWidget({
    super.key,
    required this.totalAmountController,
    required this.advancePaymentController,
    required this.pricingError,
    required this.currentBalance,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 2.h),

          /// Total Amount
          TextField(
            controller: totalAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Total Amount',
              prefixText: '₦ ',
              border: const OutlineInputBorder(),
              errorText: pricingError,
            ),
            onChanged: (_) => onCalculate(),
          ),

          SizedBox(height: 2.h),

          /// Advance Payment
          TextField(
            controller: advancePaymentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Initial Deposit',
              prefixText: '₦ ',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => onCalculate(),
          ),

          SizedBox(height: 2.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Initial deposit counts as the first payment.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Balance after deposit: ₦${currentBalance < 0 ? '0.00' : currentBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pricingError == null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
