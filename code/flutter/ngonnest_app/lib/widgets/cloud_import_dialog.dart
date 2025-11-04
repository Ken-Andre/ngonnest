import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';
import '../services/cloud_import_service.dart';
import '../services/console_logger.dart';
import '../services/error_logger_service.dart';

/// Dialog widget for cloud data import with options to import, merge, or skip
/// Shows progress during import and displays results with entity counts
class CloudImportDialog extends StatefulWidget {
  final CloudImportService cloudImportService;
  final VoidCallback? onImportComplete;

  const CloudImportDialog({
    super.key,
    required this.cloudImportService,
    this.onImportComplete,
  });

  @override
  State<CloudImportDialog> createState() => _CloudImportDialogState();
}

class _CloudImportDialogState extends State<CloudImportDialog> {
  ImportDialogState _state = ImportDialogState.options;
  ImportResult? _importResult;
  String _currentOperation = '';
  bool _canCancel = true;
  double _progress = 0.0;
  int _currentStep = 0;
  int _totalSteps = 4;
  bool _importCancelled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(
        l10n.cloudImportTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: _buildContent(context, l10n),
      actions: _buildActions(context, l10n),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    switch (_state) {
      case ImportDialogState.options:
        return _buildOptionsContent(context, l10n);
      case ImportDialogState.progress:
        return _buildProgressContent(context, l10n);
      case ImportDialogState.success:
        return _buildSuccessContent(context, l10n);
      case ImportDialogState.error:
        return _buildErrorContent(context, l10n);
    }
  }

  Widget _buildOptionsContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cloudImportMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        
        // Import option
        _buildOptionCard(
          context: context,
          icon: CupertinoIcons.cloud_download,
          title: l10n.importOption,
          description: l10n.importOptionDescription,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _handleImport(ImportAction.import),
        ),
        const SizedBox(height: 12),
        
        // Merge option
        _buildOptionCard(
          context: context,
          icon: CupertinoIcons.arrow_merge,
          title: l10n.mergeOption,
          description: l10n.mergeOptionDescription,
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => _handleImport(ImportAction.merge),
        ),
        const SizedBox(height: 12),
        
        // Skip option
        _buildOptionCard(
          context: context,
          icon: CupertinoIcons.xmark_circle,
          title: l10n.skipOption,
          description: l10n.skipOptionDescription,
          color: Theme.of(context).colorScheme.outline,
          onTap: () => _handleSkip(),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress indicator
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _progress,
                strokeWidth: 4,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${(_progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Progress title
        Text(
          l10n.importInProgress,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        // Current operation
        Text(
          _currentOperation,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Progress steps indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSteps, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        
        // Step indicator text
        Text(
          '${_currentStep + 1} / $_totalSteps',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(BuildContext context, AppLocalizations l10n) {
    final result = _importResult!;
    final isPartialSuccess = result.isPartialSuccess;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isPartialSuccess 
                ? Theme.of(context).colorScheme.secondary 
                : Theme.of(context).colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            isPartialSuccess 
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.checkmark_circle_fill,
            color: isPartialSuccess 
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPartialSuccess ? l10n.importPartialSuccess : l10n.importSuccess,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.importSuccessMessage,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Import summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total imported
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.entitiesImported(result.totalImported),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Detailed breakdown
              if (result.householdsImported > 0)
                _buildSummaryRow(
                  context,
                  CupertinoIcons.home,
                  l10n.householdsImported(result.householdsImported),
                  isSuccess: true,
                ),
              if (result.productsImported > 0)
                _buildSummaryRow(
                  context,
                  CupertinoIcons.cube_box,
                  l10n.productsImported(result.productsImported),
                  isSuccess: true,
                ),
              if (result.budgetsImported > 0)
                _buildSummaryRow(
                  context,
                  CupertinoIcons.money_dollar_circle,
                  l10n.budgetsImported(result.budgetsImported),
                  isSuccess: true,
                ),
              if (result.purchasesImported > 0)
                _buildSummaryRow(
                  context,
                  CupertinoIcons.cart,
                  l10n.purchasesImported(result.purchasesImported),
                  isSuccess: true,
                ),
              
              // Show partial failure warning if applicable
              if (isPartialSuccess && result.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Certaines données n\'ont pas pu être importées: ${result.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, IconData icon, String text, {bool isSuccess = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSuccess 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (isSuccess)
            Icon(
              CupertinoIcons.checkmark,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            )
          else
            Icon(
              CupertinoIcons.xmark,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, AppLocalizations l10n) {
    final result = _importResult;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.importError,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        // Error message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result?.error ?? 'Unknown error',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Show partial results if any data was imported before failure
        if (result != null && result.totalImported > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Données importées avant l\'erreur:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (result.householdsImported > 0)
                  _buildSummaryRow(
                    context,
                    CupertinoIcons.home,
                    l10n.householdsImported(result.householdsImported),
                    isSuccess: true,
                  ),
                if (result.productsImported > 0)
                  _buildSummaryRow(
                    context,
                    CupertinoIcons.cube_box,
                    l10n.productsImported(result.productsImported),
                    isSuccess: true,
                  ),
                if (result.budgetsImported > 0)
                  _buildSummaryRow(
                    context,
                    CupertinoIcons.money_dollar_circle,
                    l10n.budgetsImported(result.budgetsImported),
                    isSuccess: true,
                  ),
                if (result.purchasesImported > 0)
                  _buildSummaryRow(
                    context,
                    CupertinoIcons.cart,
                    l10n.purchasesImported(result.purchasesImported),
                    isSuccess: true,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    switch (_state) {
      case ImportDialogState.options:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ];
      
      case ImportDialogState.progress:
        return [
          if (_canCancel)
            TextButton(
              onPressed: () => _handleCancel(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
        ];
      
      case ImportDialogState.success:
        return [
          ElevatedButton(
            onPressed: () {
              widget.onImportComplete?.call();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.ok),
          ),
        ];
      
      case ImportDialogState.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleRetry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.retry),
          ),
        ];
    }
  }

  Future<void> _handleImport(ImportAction action) async {
    setState(() {
      _state = ImportDialogState.progress;
      _canCancel = false;
      _progress = 0.0;
      _currentStep = 0;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      // Step 1: Import households
      setState(() {
        _currentOperation = l10n.importingHouseholds;
        _currentStep = 0;
        _progress = 0.1;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 2: Import products
      setState(() {
        _currentOperation = l10n.importingProducts;
        _currentStep = 1;
        _progress = 0.4;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 3: Import budgets
      setState(() {
        _currentOperation = l10n.importingBudgets;
        _currentStep = 2;
        _progress = 0.7;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 4: Import purchases
      setState(() {
        _currentOperation = l10n.importingPurchases;
        _currentStep = 3;
        _progress = 0.9;
      });
      await Future.delayed(const Duration(milliseconds: 300));

      // Perform actual import
      final result = await widget.cloudImportService.importAllData();
      
      setState(() {
        _progress = 1.0;
        _currentStep = _totalSteps;
        _importResult = result;
        _state = result.success ? ImportDialogState.success : ImportDialogState.error;
      });

      ConsoleLogger.info('[CloudImportDialog] Import completed: ${result.success}');
      
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CloudImportDialog',
        operation: '_handleImport',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'action': action.toString()},
      );

      setState(() {
        _importResult = ImportResult()
          ..success = false
          ..error = e.toString();
        _state = ImportDialogState.error;
      });
    }
  }

  void _handleSkip() {
    Navigator.of(context).pop(false);
  }

  void _handleCancel() {
    setState(() {
      _importCancelled = true;
    });
    Navigator.of(context).pop(false);
  }

  void _handleRetry() {
    setState(() {
      _state = ImportDialogState.options;
      _importResult = null;
      _currentOperation = '';
      _canCancel = true;
      _progress = 0.0;
      _currentStep = 0;
    });
  }
}

/// Enum representing the different states of the import dialog
enum ImportDialogState {
  options,
  progress,
  success,
  error,
}

/// Enum representing the different import actions
enum ImportAction {
  import,
  merge,
}