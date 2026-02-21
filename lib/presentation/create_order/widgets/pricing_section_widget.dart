import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PricingSectionWidget extends StatelessWidget {
  final TextEditingController totalAmountController;
  final TextEditingController advancePaymentController;
  final VoidCallback onCalculate;

  const PricingSectionWidget({
    super.key,
    required this.totalAmountController,
    required this.advancePaymentController,
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
            decoration: const InputDecoration(
              labelText: 'Total Amount',
              prefixText: '₦ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onCalculate(),
          ),

          SizedBox(height: 2.h),

          /// Advance Payment
          TextField(
            controller: advancePaymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Advance Payment',
              prefixText: '₦ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onCalculate(),
          ),
        ],
      ),
    );
  }
}
