import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/objet.dart';

/// Widget pour sélectionner la méthode de prévision pour les consommables
/// Radio buttons entre fréquence d'achat et consommation journalière
class PredictionMethodSelector extends StatefulWidget {
  final MethodePrevision? selectedMethod;
  final Function(MethodePrevision)? onMethodChanged;
  final bool enabled;

  const PredictionMethodSelector({
    super.key,
    this.selectedMethod,
    this.onMethodChanged,
    this.enabled = true,
  });

  @override
  State<PredictionMethodSelector> createState() => _PredictionMethodSelectorState();
}

class _PredictionMethodSelectorState extends State<PredictionMethodSelector> {
  MethodePrevision? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod ?? MethodePrevision.frequence;
  }

  @override
  void didUpdateWidget(PredictionMethodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMethod != oldWidget.selectedMethod) {
      setState(() {
        _selectedMethod = widget.selectedMethod ?? MethodePrevision.frequence;
      });
    }
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
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec tooltip
          Row(
            children: [
              Text(
                'Méthode de prévision',
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
          const SizedBox(height: 16),

          // Radio buttons
          _buildMethodOption(
            method: MethodePrevision.frequence,
            title: 'Fréquence d\'achat',
            subtitle: 'Je sais tous les combien j\'achète',
            example: 'Ex: Tous les 30 jours',
            icon: CupertinoIcons.calendar,
          ),
          const SizedBox(height: 12),
          _buildMethodOption(
            method: MethodePrevision.debit,
            title: 'Consommation journalière',
            subtitle: 'Je sais combien j\'utilise par jour',
            example: 'Ex: 2 unités par jour',
            icon: CupertinoIcons.chart_bar,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required MethodePrevision method,
    required String title,
    required String subtitle,
    required String example,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: widget.enabled
            ? () {
                setState(() {
                  _selectedMethod = method;
                });
                widget.onMethodChanged?.call(method);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button with Material Design style
              Radio<MethodePrevision>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: widget.enabled
                    ? (MethodePrevision? value) {
                        if (value != null) {
                          setState(() {
                            _selectedMethod = value;
                          });
                          widget.onMethodChanged?.call(value);
                        }
                      }
                    : null,
                activeColor: Theme.of(context).colorScheme.primary,
                fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Theme.of(context).colorScheme.outline.withOpacity(0.5);
                }),
              ),
              const SizedBox(width: 12),

              // Icon
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      example,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Méthodes de prévision'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez la méthode qui vous convient le mieux :\n',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '📅 Fréquence d\'achat :\n'
                'Pratique si vous achetez régulièrement.\n'
                'Ex: "J\'achète du savon tous les 30 jours"\n\n'
                '📊 Consommation journalière :\n'
                'Pratique si vous savez votre usage quotidien.\n'
                'Ex: "Je consomme 2 unités de savon par jour"',
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
