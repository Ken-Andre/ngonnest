import 'package:flutter/material.dart';
import 'package:ngonnest_app/l10n/app_localizations.dart';

/// Utility service to show user feedback via snackbars or dialogs.
class FeedbackService {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Deprecated: Use [showError] instead.
  @Deprecated('Use showError instead')
  static void showErrorBasic(BuildContext context, String message) {
    showError(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orange);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue);
  }

  static void showSyncErrorDialog(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title ?? 'Erreur de synchronisation'),
        content: Text(message),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onCancel();
              },
              child: const Text('Annuler'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  static void showTimeoutError(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final message = localizations?.requestTimedOut ?? 'Request timed out';
    showError(context, message);
  }

  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    final localizations = AppLocalizations.of(context);
    final message = localizations?.networkError ?? 
        'Network error. Please verify your internet connection.';
    showError(context, message, onRetry: onRetry);
  }

  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Enhanced error methods with retry option
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: onRetry != null
            ? SnackBarAction(label: 'Réessayer', onPressed: onRetry)
            : null,
      ),
    );
  }
}