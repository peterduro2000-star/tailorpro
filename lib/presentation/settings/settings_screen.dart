import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';

import '../../presentation/purchase/purchase_screen.dart';
import '../../models/license_model.dart';
import '../../repositories/backup_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupRepository _backupRepository = BackupRepository();
  bool _isProcessing = false;
  List<FileSystemEntity> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backups = await _backupRepository.getBackupFiles();
    if (!mounted) return;
    setState(() {
      _backups = backups;
    });
  }

  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);

    try {
      final backupFile = await _backupRepository.exportDatabase();

      if (backupFile != null) {
        // Clean old backups
        await _backupRepository.cleanOldBackups(keepCount: 5);

        // Reload backup list
        await _loadBackups();

        // Show success and options
        if (mounted) {
          final result = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Backup Created'),
              content: const Text('What would you like to do with the backup?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'done'),
                  child: const Text('Done'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'share'),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          );

          if (result == 'share') {
            await _backupRepository.shareBackup(backupFile);
          }
        }
      } else {
        _showError('Failed to create backup');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;
      if (!filePath.toLowerCase().endsWith('.db')) {
        _showError('Please select a TailorPro backup file (.db)');
        return;
      }
      if (!mounted) return;

      // Confirm import
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Import Backup?'),
          content: const Text(
              'This will replace all current data with the backup.\n\n'
              'Current data will be lost. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isProcessing = true);

      final success = await _backupRepository.importDatabase(filePath);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Restart app or navigate to dashboard
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        _showError('Failed to import backup');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();
    if (!mounted) return;

    navigator.popUntil((route) => route.isFirst);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildSectionCard(
                  theme: theme,
                  title: 'Account',
                  icon: Icons.person_outline,
                  children: [
                    _buildSettingsTile(
                      theme: theme,
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Leave this account on this device',
                      iconColor: colorScheme.error,
                      textColor: colorScheme.error,
                      onTap: _handleSignOut,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSectionCard(
                  theme: theme,
                  title: 'Upgrade',
                  icon: Icons.upgrade_outlined,
                  children: [
                    _buildSettingsTile(
                      theme: theme,
                      icon: Icons.shopping_bag_outlined,
                      title: authProvider.hasPremiumAccess
                          ? 'Manage license'
                          : 'Upgrade to Premium',
                      subtitle: authProvider.hasPremiumAccess
                          ? 'Your active plan: ${authProvider.effectiveTier.displayName}'
                          : 'Unlock more customers and premium features',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PurchaseScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSettingsTile(
                      theme: theme,
                      icon: Icons.refresh,
                      title: 'Restore purchases',
                      subtitle: 'Recover purchases from Google Play',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PurchaseScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSectionCard(
                  theme: theme,
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.dark_mode_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme in TailorPro'),
                      value: themeProvider.isDarkMode(context),
                      onChanged: themeProvider.setDarkMode,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSectionCard(
                  theme: theme,
                  title: 'Data Backup',
                  icon: Icons.cloud_upload_outlined,
                  children: [
                    _buildSettingsTile(
                      theme: theme,
                      icon: Icons.backup_outlined,
                      title: 'Create Backup Now',
                      subtitle: 'Save your current data to a backup file',
                      onTap: _createBackup,
                    ),
                    _buildDivider(theme),
                    _buildSettingsTile(
                      theme: theme,
                      icon: Icons.restore_outlined,
                      title: 'Restore from Backup',
                      subtitle: 'Import a saved TailorPro backup file',
                      onTap: _importBackup,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSectionCard(
                  theme: theme,
                  title: 'Recent Backups',
                  icon: Icons.history_outlined,
                  trailing: Text(
                    '${_backups.length} backup${_backups.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    if (_backups.isEmpty)
                      _buildEmptyBackupsState(theme)
                    else
                      ..._backups
                          .take(5)
                          .map((backup) => _buildBackupItem(backup, theme)),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSectionCard(
                  theme: theme,
                  title: 'Backup Tips',
                  icon: Icons.info_outline,
                  children: [
                    _buildTip(theme, 'Back up regularly (weekly recommended)'),
                    _buildTip(
                        theme, 'Share backup to WhatsApp or Google Drive'),
                    _buildTip(
                        theme, 'Keep backup file safe when changing phones'),
                    _buildTip(theme, 'Test restore once to ensure it works'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme: theme,
            title: title,
            icon: icon,
            trailing: trailing,
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSettingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: effectiveTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }

  Widget _buildEmptyBackupsState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No backups yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your first backup to protect your data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem(FileSystemEntity backup, ThemeData theme) {
    final file = backup as File;
    final fileName = file.path.split('/').last;
    final dateStr =
        fileName.replaceAll('tailorpro_backup_', '').replaceAll('.db', '');

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, color: theme.colorScheme.primary),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.replaceAll('-', '/').substring(0, 16),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                FutureBuilder<String>(
                  future: _backupRepository.getBackupSize(file),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Calculating...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _backupRepository.shareBackup(file),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
