import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/objet.dart';

class QuickQuantityUpdate extends StatefulWidget {
  final Objet objet;
  final Function(double newQuantity) onQuantityChanged;

  const QuickQuantityUpdate({
    super.key,
    required this.objet,
    required this.onQuantityChanged,
  });

  @override
  State<QuickQuantityUpdate> createState() => _QuickQuantityUpdateState();
}

class _QuickQuantityUpdateState extends State<QuickQuantityUpdate> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.objet.quantiteRestante.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    // Select all text when starting to edit
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.objet.quantiteRestante.toString();
    });
  }

  Future<void> _saveQuantity() async {
    final newQuantityText = _controller.text.trim();
    if (newQuantityText.isEmpty) {
      _cancelEditing();
      return;
    }

    final newQuantity = double.tryParse(newQuantityText);
    if (newQuantity == null || newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une quantité valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newQuantity == widget.objet.quantiteRestante) {
      _cancelEditing();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onQuantityChanged(newQuantity);
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantité mise à jour: ${newQuantity.toString()} ${widget.objet.unite}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _cancelEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.objet.type != TypeObjet.consommable) {
      // Only show quantity updates for consumables
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isEditing) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.6, // Max 60% of screen width
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 2,
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    suffix: Text(
                      widget.objet.unite,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  autofocus: true,
                  onSubmitted: (_) => _saveQuantity(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.check, size: 18),
              onPressed: _saveQuantity,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              color: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _cancelEditing,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              color: Colors.red,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${widget.objet.quantiteRestante} ${widget.objet.unite}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
