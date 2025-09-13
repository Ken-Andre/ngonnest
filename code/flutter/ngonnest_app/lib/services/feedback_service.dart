import 'package:flutter/material.dart';

/// Utility service to show user feedback via snackbars or dialogs.
class FeedbackService {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.red);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.orange);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, Colors.blue);
  }

  static void showSyncErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showTimeoutError(BuildContext context) {
    showError(context, 'Request timed out');
  }

  static void showNetworkError(BuildContext context) {
    showError(context, 'Network error');
  }

  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
