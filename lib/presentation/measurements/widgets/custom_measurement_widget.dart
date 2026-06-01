import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import './measurement_input_widget.dart';

/// A widget for adding custom measurements with name and value inputs
class CustomMeasurementWidget extends StatelessWidget {
  final List<Map<String, TextEditingController>> customMeasurements;
  final VoidCallback onAddMeasurement;
  final Function(int) onRemoveMeasurement;
  final String unit;

  const CustomMeasurementWidget({
    super.key,
    required this.customMeasurements,
    required this.onAddMeasurement,
    required this.onRemoveMeasurement,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Measurements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: onAddMeasurement,
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: theme.colorScheme.primary,
                size: 28,
              ),
              tooltip: 'Add Custom Measurement',
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (customMeasurements.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info_outline',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Tap + to add custom measurements',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...customMeasurements.asMap().entries.map((entry) {
            final index = entry.key;
            final measurement = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Custom ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemoveMeasurement(index),
                        icon: CustomIconWidget(
                          iconName: 'delete_outline',
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: measurement['name']!,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Measurement Name',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'label_outline',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  MeasurementInputWidget(
                    label: 'Value',
                    iconName: 'straighten',
                    controller: measurement['value']!,
                    unit: unit,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
