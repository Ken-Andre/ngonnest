import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'error_logger_service.dart';

/// Service for creating and managing database backups
/// Used primarily for UUID migration safety
class DatabaseBackupService {
  /// Creates a backup of the current database
  /// Returns the path to the backup file
  static Future<String> createBackup() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'ngonnest.db');

      // Check if database exists
      if (!await File(dbPath).exists()) {
        throw Exception('Database file not found at $dbPath');
      }

      // Create backup directory
      final backupDir = await _getBackupDirectory();

      // Generate backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = join(backupDir.path, 'ngonnest_backup_$timestamp.db');

      // Copy database file
      await File(dbPath).copy(backupPath);

      debugPrint('[DatabaseBackup] Backup created at: $backupPath');

      // Clean up old backups (keep only last 5)
      await _cleanupOldBackups(backupDir);

      return backupPath;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'DatabaseBackupService',
        operation: 'createBackup',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.critical,
      );
      rethrow;
    }
  }

  /// Restores database from a backup file
  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, 'ngonnest.db');

      // Check if backup exists
      if (!await File(backupPath).exists()) {
        throw Exception('Backup file not found at $backupPath');
      }

      // Close any open database connections
      await deleteDatabase(dbPath);

      // Copy backup to database location
      await File(backupPath).copy(dbPath);

      debugPrint('[DatabaseBackup] Database restored from: $backupPath');
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'DatabaseBackupService',
        operation: 'restoreFromBackup',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.critical,
      );
      rethrow;
    }
  }

  /// Lists all available backups
  static Future<List<FileSystemEntity>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backups = backupDir
          .listSync()
          .where((file) => file.path.endsWith('.db'))
          .toList();

      // Sort by modification date (newest first)
      backups.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return backups;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'DatabaseBackupService',
        operation: 'listBackups',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      return [];
    }
  }

  /// Deletes a specific backup file
  static Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[DatabaseBackup] Deleted backup: $backupPath');
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'DatabaseBackupService',
        operation: 'deleteBackup',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
    }
  }

  /// Gets or creates the backup directory
  static Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(join(appDir.path, 'db_backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// Cleans up old backups, keeping only the most recent ones
  static Future<void> _cleanupOldBackups(
    Directory backupDir, {
    int keepCount = 5,
  }) async {
    try {
      final backups = await listBackups();

      if (backups.length > keepCount) {
        // Delete oldest backups
        for (int i = keepCount; i < backups.length; i++) {
          await backups[i].delete();
          debugPrint('[DatabaseBackup] Deleted old backup: ${backups[i].path}');
        }
      }
    } catch (e) {
      debugPrint('[DatabaseBackup] Error cleaning up old backups: $e');
    }
  }

  /// Verifies backup integrity by checking if it can be opened
  static Future<bool> verifyBackup(String backupPath) async {
    try {
      final db = await openDatabase(backupPath, readOnly: true);

      // Try to query a simple table to verify integrity
      await db.rawQuery('SELECT COUNT(*) FROM sqlite_master');

      await db.close();
      return true;
    } catch (e) {
      debugPrint('[DatabaseBackup] Backup verification failed: $e');
      return false;
    }
  }
}
