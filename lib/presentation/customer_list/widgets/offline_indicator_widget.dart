import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sync_status_provider.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Status banner that reflects the app's *real* synchronization state.
///
/// It reads [SyncStatusProvider] and reacts automatically whenever
/// connectivity changes, a sync starts, succeeds, or fails. The widget no
/// longer fabricates an offline state.
class OfflineIndicatorWidget extends StatelessWidget {
  const OfflineIndicatorWidget({super.key});

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getLastSyncedLabel(DateTime? lastSync) {
    if (lastSync == null) return 'never';
    return _getTimeAgo(lastSync);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncStatus = context.watch<SyncStatusProvider>();
    final status = syncStatus.status;

    // Online with no prior successful sync: prefer to show nothing rather
    // than a misleading "synced" message.
    if (status == SyncStatus.online && syncStatus.lastSuccessfulSync == null) {
      return const SizedBox.shrink();
    }

    late final String iconName;
    late final Color color;
    late final String label;
    VoidCallback? onTap;

    switch (status) {
      case SyncStatus.online:
        iconName = 'cloud_done';
        color = theme.colorScheme.primary;
        label =
            'Synced ${_getTimeAgo(syncStatus.lastSuccessfulSync!)}';
        break;
      case SyncStatus.syncing:
        iconName = 'sync';
        color = theme.colorScheme.onSurfaceVariant;
        label = 'Syncing...';
        break;
      case SyncStatus.offline:
        iconName = 'cloud_off';
        color = theme.colorScheme.onSurfaceVariant;
        label =
            'Offline · Changes will sync automatically · Last synced ${_getLastSyncedLabel(syncStatus.lastSuccessfulSync)}';
        break;
      case SyncStatus.failed:
        iconName = 'error';
        color = theme.colorScheme.error;
        label = 'Sync failed · Tap to retry';
        onTap = () => context.read<AuthProvider>().startCloudSync();
        break;
    }

    final child = Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: status == SyncStatus.failed
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: status == SyncStatus.failed
                    ? theme.colorScheme.onErrorContainer
                    : color,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
