import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Widget wrapper pour encapsuler les écrans principaux et intégrer
/// la barre de navigation inférieure de manière réutilisable
class MainNavigationWrapper extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;

  const MainNavigationWrapper({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: body,
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final tabs = [
      {'icon': CupertinoIcons.house, 'label': 'Accueil'},
      {'icon': CupertinoIcons.cube_box, 'label': 'Inventaire'},
      {'icon': CupertinoIcons.add, 'label': 'Ajouter'},
      {'icon': CupertinoIcons.money_dollar, 'label': 'Budget'},
      {'icon': CupertinoIcons.gear, 'label': 'Paramètres'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = index == currentIndex;

            return Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => onTabChanged(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        tab['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: Text(tab['label'] as String),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
