import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/smart_validator.dart';
import 'error_feedback_widget.dart';

/// Widget pour saisir la consommation journalière (quand MethodePrevision.debit)
/// Conditionnellement affiché selon la méthode de prévision sélectionnée
class ConsumptionInputField extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool enabled;
  final String unit;

  const ConsumptionInputField({
    super.key,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.unit = 'unités',
  });

  @override
  State<ConsumptionInputField> createState() => _ConsumptionInputFieldState();
}

class _ConsumptionInputFieldState extends State<ConsumptionInputField> {
  late TextEditingController _controller;
  ValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(ConsumptionInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validateConsumption(String value) {
    final result = SmartValidator.validateProductQuantity(
      value,
      context: 'consumption',
      maxAllowed: 1000, // Max 1000 unités par jour
    );
    setState(() {
      _validationResult = result;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _validationResult?.isValid == false
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: _validationResult?.isValid == false ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec tooltip
          Row(
            children: [
              Text(
                'Consommation journalière',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelpDialog(context),
                child: Icon(
                  CupertinoIcons.question_circle,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Champ de saisie
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: _validateConsumption,
                  decoration: InputDecoration(
                    hintText: 'Ex: 2.5',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  validator: (value) {
                    final result = SmartValidator.validateProductQuantity(
                      value ?? '',
                      context: 'consumption',
                      maxAllowed: 1000,
                    );
                    return result.isValid ? null : result.userMessage;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.unit}/jour',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Exemple et feedback
          const SizedBox(height: 8),
          Text(
            'Ex: Si vous utilisez 2 unités par jour, entrez "2"',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),

          // Feedback de validation
          ErrorFeedbackWidget(
            validationResult: _validationResult,
            showDebugInfo: false,
            padding: const EdgeInsets.only(top: 8),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consommation journalière'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indiquez votre consommation quotidienne :\n',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '📊 Comment calculer ?\n'
                'Observez votre usage sur quelques jours :\n'
                '• Savon : 1 par douche\n'
                '• Dentifrice : 1 par brossage\n'
                '• Lait : 2 verres par jour\n\n'
                '💡 Conseil :\n'
                'Prenez une moyenne sur 7 jours pour être précis.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
