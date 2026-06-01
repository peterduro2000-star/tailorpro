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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h), // was 3.h
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
      child: Row(                                   // changed Column → Row
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (smaller)
          Container(
            width: 12.w,                            // was 20.w
            height: 12.w,                           // was 20.w
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: gender.toLowerCase() == 'female' ? 'person' : 'person_outline',
                size: 6.w,                          // was 10.w
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 3.w),

          // Name + Phone + Notes (middle, expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Text(
                    notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          SizedBox(width: 2.w),

          // Contact buttons (right side, compact)
          _buildContactButton(
            context: context,
            icon: 'phone',
            label: 'Call',
            onTap: onCall,
            theme: theme,
          ),
          SizedBox(width: 2.w),
          _buildContactButton(
            context: context,
            icon: 'chat',
            label: 'WA',
            onTap: onWhatsApp,
            theme: theme,
            color: const Color(0xFF25D366),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.h), // was 6.w / 1.5.h
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(                              // icon over label — compact
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 4.w,                           // was 5.w
              color: Colors.white,
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
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