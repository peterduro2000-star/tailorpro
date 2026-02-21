import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_helper.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Export database to file
  Future<File?> exportDatabase() async {
    try {
      // Get current database file
      final dbPath = await _dbHelper.database.then((db) => db.path);
      final dbFile = File(dbPath);

      // Create backup directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Storage not available');

      final backupDir = Directory('${directory.path}/TailorPro/Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create backup file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupPath = '${backupDir.path}/tailorpro_backup_$timestamp.db';
      
      // Copy database to backup location
      final backupFile = await dbFile.copy(backupPath);
      
      return backupFile;
    } catch (e) {
      print('Error exporting database: $e');
      return null;
    }
  }

  /// Import database from file
  Future<bool> importDatabase(String filePath) async {
    try {
      final backupFile = File(filePath);
      
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      // Get current database path
      final dbPath = await _dbHelper.database.then((db) => db.path);
      
      // Close current database
      await _dbHelper.close();
      
      // Replace with backup
      await backupFile.copy(dbPath);
      
      // Reinitialize database
      await _dbHelper.database;
      
      return true;
    } catch (e) {
      print('Error importing database: $e');
      return false;
    }
  }

  /// Share backup file via WhatsApp, email, etc.
  Future<void> shareBackup(File backupFile) async {
    try {
      final xFile = XFile(backupFile.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'TailorPro Backup - ${DateTime.now().toString().split(' ')[0]}',
        text: 'TailorPro database backup. Keep this file safe!',
      );
    } catch (e) {
      print('Error sharing backup: $e');
    }
  }

  /// Get list of all backups
  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return [];

      final backupDir = Directory('${directory.path}/TailorPro/Backups');
      if (!await backupDir.exists()) return [];

      final files = backupDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList();
      
      // Sort by date (newest first)
      files.sort((a, b) => b.path.compareTo(a.path));
      
      return files;
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }

  /// Delete old backups (keep only last N backups)
  Future<void> cleanOldBackups({int keepCount = 5}) async {
    try {
      final backups = await getBackupFiles();
      
      if (backups.length > keepCount) {
        for (var i = keepCount; i < backups.length; i++) {
          await backups[i].delete();
        }
      }
    } catch (e) {
      print('Error cleaning backups: $e');
    }
  }

  /// Get backup file size
  Future<String> getBackupSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}