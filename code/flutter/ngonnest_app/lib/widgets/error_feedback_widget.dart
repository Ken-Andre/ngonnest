import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/error_logger_service.dart';

/// Widget d'affichage intelligent des erreurs et feedback utilisateur
/// Fournit des portes de debuggage pour les développeurs
class ErrorFeedbackWidget extends StatelessWidget {
  final dynamic validationResult;
  final bool showDebugInfo;
  final VoidCallback? onSuggestionTap;
  final EdgeInsetsGeometry? padding;
  final TextStyle? userMessageStyle;
  final TextStyle? debugTextStyle;

  const ErrorFeedbackWidget({
    super.key,
    required this.validationResult,
    this.showDebugInfo = false,
    this.onSuggestionTap,
    this.padding,
    this.userMessageStyle,
    this.debugTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Si pas d'erreur ou de résultat, rien à afficher
    if (validationResult == null || validationResult.isValid == true) {
      return const SizedBox.shrink();
    }

    final hasSuggestions = validationResult.suggestions?.isNotEmpty == true;
    final hasDebugInfo = kDebugMode && showDebugInfo && validationResult.errorCode != null;

    return Container(
      padding: padding ?? const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message utilisateur principal
          _buildUserMessage(),
          const SizedBox(height: 8),

          // Suggestions de correction
          if (hasSuggestions) ...[
            ...validationResult.suggestions.map((suggestion) =>
              _buildSuggestionChip(suggestion, context)
            ),
          ],

          // Porte de debuggage (DEBUG MODE uniquement)
          if (hasDebugInfo) _buildDebugSection(context),
        ],
      ),
    );
  }

  /// Message utilisateur principal
  Widget _buildUserMessage() {
    final severity = validationResult.severity ?? ErrorSeverity.medium;
    final color = _getSeverityColor(severity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _getSeverityIcon(severity),
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            validationResult.userMessage ?? 'Une erreur s\'est produite',
            style: userMessageStyle ?? TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Chips pour les suggestions pratiques
  Widget _buildSuggestionChip(String suggestion, BuildContext context) {
    return GestureDetector(
      onTap: onSuggestionTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section de debuggage (portes de debuggage professionelles)
  Widget _buildDebugSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'DEBUG INFO',
                style: debugTextStyle ?? TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Code d'erreur
          if (validationResult.errorCode != null) ...[
            _buildDebugRow('Code:', validationResult.errorCode, context),
          ],

          // Champ concerné
          if (validationResult.field != null && validationResult.field.isNotEmpty) ...[
            _buildDebugRow('Champ:', validationResult.field, context),
          ],

          // Gravité
          if (validationResult.severity != null) ...[
_buildDebugRow('Gravité:', validationResult.severity.toString().split('.').last.toUpperCase(), context),
          ],

          const SizedBox(height: 8),

          // Bouton pour détails techniques (stack trace)
          TextButton.icon(
            onPressed: () => _showTechnicalDetails(context),
            icon: Icon(
              Icons.code,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'DÉTAILS TECHNIQUES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne d'information de debug
  Widget _buildDebugRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: debugTextStyle ?? TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: debugTextStyle ?? TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialogue avec détails techniques complets
  void _showTechnicalDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.bug_report,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Détails Techniques',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message technique
              if (validationResult.technicalMessage != null) ...[
                _buildTechDetailRow('Message Technique:', validationResult.technicalMessage),
                const Divider(height: 16),
              ],

              // Métadonnées
              if (validationResult.metadata != null) ...[
                Text(
                  'Métadonnées:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Text(
                    validationResult.metadata.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n'),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
                const Divider(height: 16),
              ],

              // Actions disponibles
              Text(
                'Actions Débogage:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Log une erreur test
                      ErrorLoggerService.logError(
                        component: 'DebugDialog',
                        operation: 'testError',
                        error: 'User-triggered test error',
                        stackTrace: StackTrace.current,
                        severity: ErrorSeverity.low,
                        metadata: {
                          'source': 'debug_dialog',
                          'timestamp': DateTime.now().toIso8601String(),
                        },
                      );
                    },
                    icon: const Icon(Icons.bug_report, size: 14),
                    label: const Text('Test Error', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final logs = await ErrorLoggerService.getAllLogs();
                      final recentLogs = logs.where((log) =>
                        log.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 5)))
                      ).toList();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${recentLogs.length} erreurs dans les 5 dernières minutes'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.history, size: 14),
                    label: const Text('View Logs', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTechDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur selon la gravité
  Color _getSeverityColor(dynamic severity) {
    if (severity == null) return Colors.red.shade600;

    final severityString = severity.toString().split('.').last;

    if (severityString == 'info') return Colors.blue.shade600;
    if (severityString == 'warning') return Colors.orange.shade600;
    if (severityString == 'error') return Colors.red.shade600;
    if (severityString == 'critical') return Colors.red.shade900;

    return Colors.red.shade600;
  }

  /// Icône selon la gravité
  IconData _getSeverityIcon(dynamic severity) {
    if (severity == null) return Icons.error_outline;

    final severityString = severity.toString().split('.').last;

    if (severityString == 'info') return Icons.info_outline;
    if (severityString == 'warning') return Icons.warning_amber_outlined;
    if (severityString == 'error') return Icons.error_outline;
    if (severityString == 'critical') return Icons.dangerous_outlined;

    return Icons.error_outline;
  }
}
