import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/smart_validator.dart';
import 'error_feedback_widget.dart';

/// Widget pour saisir ou calculer automatiquement la durée de vie pour durables
/// Calcule automatiquement si le produit a une durée connue dans le catalogue
class DurationCalculator extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool enabled;
  final DateTime? purchaseDate;
  final String? productName;
  final int? knownLifespanDays; // Durée connue depuis le catalogue

  const DurationCalculator({
    super.key,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.purchaseDate,
    this.productName,
    this.knownLifespanDays,
  });

  @override
  State<DurationCalculator> createState() => _DurationCalculatorState();
}

class _DurationCalculatorState extends State<DurationCalculator> {
  late TextEditingController _controller;
  ValidationResult? _validationResult;
  bool _useAutoCalculation = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _useAutoCalculation = widget.knownLifespanDays != null;
    _updateControllerValue();
  }

  @override
  void didUpdateWidget(DurationCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.knownLifespanDays != oldWidget.knownLifespanDays ||
        widget.purchaseDate != oldWidget.purchaseDate) {
      _controller = widget.controller ?? TextEditingController();
      _useAutoCalculation = widget.knownLifespanDays != null;
      _updateControllerValue();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateControllerValue() {
    if (_useAutoCalculation && widget.knownLifespanDays != null) {
      _controller.text = widget.knownLifespanDays.toString();
    }
  }

  void _validateDuration(String value) {
    final result = SmartValidator.validateProductQuantity(
      value,
      context: 'duration',
      maxAllowed: 10000, // Max 10 ans en jours
    );
    setState(() {
      _validationResult = result;
    });
    widget.onChanged?.call(value);
  }

  void _toggleAutoCalculation(bool value) {
    setState(() {
      _useAutoCalculation = value;
      if (value && widget.knownLifespanDays != null) {
        _controller.text = widget.knownLifespanDays.toString();
        _validateDuration(_controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKnownLifespan = widget.knownLifespanDays != null;
    final daysRemaining = _calculateDaysRemaining();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _validationResult?.isValid == false
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
                'Durée de vie prévue',
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Toggle auto-calculation si durée connue
          if (hasKnownLifespan) ...[
            Row(
              children: [
                Text(
                  'Utiliser la durée standard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: _useAutoCalculation,
                  onChanged: widget.enabled ? _toggleAutoCalculation : null,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '📅 Durée standard: ${widget.knownLifespanDays} jours',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Champ de saisie
          Row(
            children: [
              Icon(
                CupertinoIcons.timer,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  enabled: widget.enabled && !_useAutoCalculation,
                  keyboardType: TextInputType.number,
                  onChanged: _validateDuration,
                  decoration: InputDecoration(
                    hintText: hasKnownLifespan
                        ? 'Ou personnaliser...'
                        : 'Ex: 365',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  validator: (value) {
                    final result = SmartValidator.validateProductQuantity(
                      value ?? '',
                      context: 'duration',
                      maxAllowed: 10000,
                    );
                    return result.isValid ? null : result.userMessage;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'jours',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Informations calculées
          if (daysRemaining != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRemainingColor(daysRemaining).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRemainingIcon(daysRemaining),
                    size: 16,
                    color: _getRemainingColor(daysRemaining),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Temps restant estimé: ${_formatDaysRemaining(daysRemaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRemainingColor(daysRemaining),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Exemples et feedback
          const SizedBox(height: 8),
          Text(
            'Exemples: Ampoule=1000j, Électroménager=3650j (10 ans)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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

  int? _calculateDaysRemaining() {
    if (widget.purchaseDate == null || _controller.text.isEmpty) return null;

    final lifespanDays = int.tryParse(_controller.text);
    if (lifespanDays == null) return null;

    final now = DateTime.now();
    final daysSincePurchase = now.difference(widget.purchaseDate!).inDays;
    final daysRemaining = lifespanDays - daysSincePurchase;

    return daysRemaining > 0 ? daysRemaining : 0;
  }

  String _formatDaysRemaining(int days) {
    if (days <= 0) return 'expiré';
    if (days < 30) return '$days jours';
    if (days < 365) return '${(days / 30).round()} mois';
    return '${(days / 365).round()} ans';
  }

  Color _getRemainingColor(int days) {
    if (days <= 0) return Colors.red;
    if (days < 30) return Colors.orange;
    if (days < 180) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _getRemainingIcon(int days) {
    if (days <= 0) return CupertinoIcons.xmark_circle;
    if (days < 30) return CupertinoIcons.exclamationmark_triangle;
    if (days < 180) return CupertinoIcons.clock;
    return CupertinoIcons.checkmark_circle;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durée de vie des biens durables'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indiquez la durée de vie estimée :\n',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '📅 Durées typiques :\n'
                '• Ampoules : 1 000 jours (3 ans)\n'
                '• Électroménager : 3 650 jours (10 ans)\n'
                '• Meubles : 5 475 jours (15 ans)\n'
                '• Électronique : 1 095 jours (3 ans)\n\n'
                '💡 Conseil :\n'
                'Utilisez la durée standard si disponible, ou ajustez selon votre expérience.',
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
