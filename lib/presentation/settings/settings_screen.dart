import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';

import '../../repositories/backup_repository.dart';
import '../../widgets/custom_icon_widget.dart';

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

          if (result == 'share' && backupFile != null) {
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

      // Confirm import
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Import Backup?'),
          content: const Text(
            'This will replace all current data with the backup.\n\n'
            'Current data will be lost. Continue?'
          ),
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
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        _showError('Failed to import backup');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Backup'),
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
                // Backup Section
                Text(
                  'Data Backup',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                
                // Create Backup Button
                ElevatedButton.icon(
                  onPressed: _createBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Create Backup Now'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(4.w),
                  ),
                ),
                
                SizedBox(height: 2.h),
                
                // Import Backup Button
                OutlinedButton.icon(
                  onPressed: _importBackup,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore from Backup'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(4.w),
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                // Recent Backups
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Backups',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_backups.length} backup${_backups.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 2.h),
                
                if (_backups.isEmpty)
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No backups yet',
                          style: theme.textTheme.titleSmall,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Create your first backup to protect your data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._backups.take(5).map((backup) => _buildBackupItem(backup, theme)).toList(),
                
                SizedBox(height: 4.h),
                
                // Info Card
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Backup Tips',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildTip('Back up regularly (weekly recommended)'),
                      _buildTip('Share backup to WhatsApp or Google Drive'),
                      _buildTip('Keep backup file safe when changing phones'),
                      _buildTip('Test restore once to ensure it works'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBackupItem(FileSystemEntity backup, ThemeData theme) {
    final fileName = backup.path.split('/').last;
    final dateStr = fileName.replaceAll('tailorpro_backup_', '').replaceAll('.db', '');
    
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
                  future: _backupRepository.getBackupSize(backup as File),
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
            onPressed: () => _backupRepository.shareBackup(backup as File),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}