import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Customer header widget displaying avatar, name, and contact information
class CustomerHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const CustomerHeaderWidget({
    super.key,
    required this.customer,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String gender = customer['gender'] ?? 'male';
    final String name = customer['name'] ?? 'Unknown Customer';
    final String phone = customer['phone'] ?? '';
    final String? notes = customer['notes'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: gender.toLowerCase() == 'female' ? 'person' : 'person_outline',
                size: 10.w,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Customer Name
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),

          // Phone Number
          if (phone.isNotEmpty)
            Text(
              phone,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Contact Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactButton(
                context: context,
                icon: 'phone',
                label: 'Call',
                onTap: onCall,
                theme: theme,
              ),
              SizedBox(width: 4.w),
              _buildContactButton(
                context: context,
                icon: 'chat',
                label: 'WhatsApp',
                onTap: onWhatsApp,
                theme: theme,
                color: Color(0xFF25D366),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? color,
  }) {
    final buttonColor = color ?? theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 5.w,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}