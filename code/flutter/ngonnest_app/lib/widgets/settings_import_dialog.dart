import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/cloud_import_service.dart';
import '../services/console_logger.dart';
import '../services/error_logger_service.dart';

/// Dialog for handling import options when enabling sync from settings
/// Provides options to keep local data, import from cloud, or merge both
class SettingsImportDialog extends StatefulWidget {
  final CloudImportService cloudImportService;
  final VoidCallback? onComplete;

  const SettingsImportDialog({
    super.key,
    required this.cloudImportService,
    this.onComplete,
  });

  @override
  State<SettingsImportDialog> createState() => _SettingsImportDialogState();
}

class _SettingsImportDialogState extends State<SettingsImportDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return CupertinoAlertDialog(
      title: Text(l10n?.importOptionsTitle ?? 'Import options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n?.chooseImportOption ?? 'Choose how to handle your existing data',
            style: const TextStyle(fontSize: 14),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isProcessing) ...[
          CupertinoDialogAction(
            child: Column(
              children: [
                Text(
                  l10n?.keepLocal ?? 'Keep local',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n?.keepLocalDescription ?? 'Upload local data to cloud',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onPressed: () => _handleKeepLocal(),
          ),
          CupertinoDialogAction(
            child: Column(
              children: [
                Text(
                  l10n?.importFromCloud ?? 'Import from cloud',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n?.importFromCloudDescription ?? 'Download data from cloud',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onPressed: () => _handleImportFromCloud(),
          ),
          CupertinoDialogAction(
            child: Column(
              children: [
                Text(
                  l10n?.mergeData ?? 'Merge',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n?.mergeDataDescription ?? 'Combine local and cloud data',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onPressed: () => _handleMergeData(),
          ),
        ] else ...[
          CupertinoDialogAction(
            child: const CupertinoActivityIndicator(),
            onPressed: null,
          ),
        ],
      ],
    );
  }

  /// Handle keeping local data (upload to cloud)
  Future<void> _handleKeepLocal() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // For "keep local", we don't import anything
      // The sync service will upload local data when enabled
      ConsoleLogger.info('[SettingsImportDialog] User chose to keep local data');
      
      if (mounted) {
        Navigator.of(context).pop('keep_local');
        widget.onComplete?.call();
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SettingsImportDialog',
        operation: 'handleKeepLocal',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Erreur lors de la configuration: $e';
        });
      }
    }
  }

  /// Handle importing from cloud
  Future<void> _handleImportFromCloud() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      ConsoleLogger.info('[SettingsImportDialog] Starting cloud data import');
      
      final result = await widget.cloudImportService.importAllData();
      
      if (result.success) {
        ConsoleLogger.info('[SettingsImportDialog] Cloud import successful');
        
        if (mounted) {
          Navigator.of(context).pop('import_cloud');
          widget.onComplete?.call();
        }
      } else {
        throw Exception(result.error ?? 'Import failed');
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SettingsImportDialog',
        operation: 'handleImportFromCloud',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Erreur lors de l\'importation: $e';
        });
      }
    }
  }

  /// Handle merging local and cloud data
  Future<void> _handleMergeData() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      ConsoleLogger.info('[SettingsImportDialog] Starting data merge');
      
      // For merge, we import cloud data and let conflict resolution handle duplicates
      final result = await widget.cloudImportService.importAllData();
      
      if (result.success) {
        ConsoleLogger.info('[SettingsImportDialog] Data merge successful');
        
        if (mounted) {
          Navigator.of(context).pop('merge');
          widget.onComplete?.call();
        }
      } else {
        throw Exception(result.error ?? 'Merge failed');
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SettingsImportDialog',
        operation: 'handleMergeData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Erreur lors de la fusion: $e';
        });
      }
    }
  }
}