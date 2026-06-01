import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// A widget that displays previous measurement sets with copy functionality
class MeasurementHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> measurementHistory;
  final Function(Map<String, dynamic>) onCopyMeasurements;

  const MeasurementHistoryWidget({
    super.key,
    required this.measurementHistory,
    required this.onCopyMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (measurementHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 2.h),
        Text(
          'Previous Measurements',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...measurementHistory.map((history) {
          final values = history['values'] as Map<String, double>? ?? {};
          final date = history['date'] as String? ?? 'Unknown date';
          final type = history['type'] as String? ?? 'Unknown';

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'calendar_today',
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                date,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            type,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => onCopyMeasurements(history),
                      icon: CustomIconWidget(
                        iconName: 'content_copy',
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      label: Text(
                        'Copy',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (values.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: values.entries.map((entry) {
                      return _buildMeasurementChip(
                        context,
                        entry.key,
                        entry.value.toString(),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMeasurementChip(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}