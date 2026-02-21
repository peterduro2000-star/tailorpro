import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MeasurementSelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? selectedMeasurement;
  final Function(Map<String, dynamic>) onMeasurementSelected;

  const MeasurementSelectionWidget({
    super.key,
    required this.customer,
    required this.selectedMeasurement,
    required this.onMeasurementSelected,
  });

  @override
  State<MeasurementSelectionWidget> createState() =>
      _MeasurementSelectionWidgetState();
}

class _MeasurementSelectionWidgetState
    extends State<MeasurementSelectionWidget> {
  List<Map<String, dynamic>> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  void _loadMeasurements() {
    if (widget.customer == null) return;

    final gender = widget.customer!["gender"] as String;

    _measurements = gender == "Male"
        ? [
            {
              "id": 1,
              "name": "Agbada Set",
              "date": "2026-01-15",
              "measurements": {
                "Neck": "16 inches",
                "Shoulder": "18 inches",
                "Chest": "42 inches",
                "Sleeve": "24 inches",
                "Length": "58 inches",
                "Waist": "36 inches",
              },
            },
            {
              "id": 2,
              "name": "Senator Suit",
              "date": "2025-12-20",
              "measurements": {
                "Neck": "16 inches",
                "Shoulder": "18 inches",
                "Chest": "42 inches",
                "Sleeve": "24 inches",
                "Length": "48 inches",
                "Waist": "36 inches",
              },
            },
          ]
        : [
            {
              "id": 3,
              "name": "Ankara Gown",
              "date": "2026-01-10",
              "measurements": {
                "Bust": "38 inches",
                "Waist": "32 inches",
                "Hips": "42 inches",
                "Shoulder": "15 inches",
                "Sleeve": "22 inches",
                "Length": "52 inches",
              },
            },
            {
              "id": 4,
              "name": "Iro and Buba",
              "date": "2025-12-15",
              "measurements": {
                "Bust": "38 inches",
                "Waist": "32 inches",
                "Hips": "42 inches",
                "Shoulder": "15 inches",
                "Sleeve": "20 inches",
                "Blouse Length": "24 inches",
                "Wrapper Length": "45 inches",
              },
            },
          ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.customer == null) {
      return _buildNoCustomerState(theme);
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Measurements', style: theme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text(
                'Choose saved measurements for ${widget.customer!["name"]}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _measurements.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _measurements.length + 1,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCreateNewButton(theme);
                    }

                    final measurement = _measurements[index - 1];
                    final isSelected =
                        widget.selectedMeasurement?["id"] == measurement["id"];

                    return _buildMeasurementCard(
                      theme,
                      measurement,
                      isSelected,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreateNewButton(ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/measurements');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'straighten',
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Measurements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Take fresh measurements for this order',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(
    ThemeData theme,
    Map<String, dynamic> measurement,
    bool isSelected,
  ) {
    final measurements = measurement["measurements"] as Map<String, dynamic>;

    return InkWell(
      onTap: () {
        widget.onMeasurementSelected(measurement);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        measurement["name"] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'calendar_today',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            measurement["date"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'check',
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: (measurements.entries.toList() as List)
                    .map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              entry.value as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList()
                    .cast<Widget>(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'straighten',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No measurements found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create new measurements for this customer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCustomerState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'person_off',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No customer selected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please select a customer first',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
