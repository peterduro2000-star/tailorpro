import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Gender selector widget with large, thumb-friendly buttons
/// Implements visual icons for male/female options
class GenderSelectorWidget extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderSelectorWidget({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildGenderButton(
                context: context,
                theme: theme,
                gender: 'Male',
                icon: 'man',
                isSelected: selectedGender == 'Male',
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildGenderButton(
                context: context,
                theme: theme,
                gender: 'Female',
                icon: 'woman',
                isSelected: selectedGender == 'Female',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton({
    required BuildContext context,
    required ThemeData theme,
    required String gender,
    required String icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onGenderSelected(gender),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 12.h,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 32,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 1.h),
            Text(
              gender,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
