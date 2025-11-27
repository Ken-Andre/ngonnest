import 'package:flutter/material.dart';

import 'console_logger.dart';
import 'app_feature_flags.dart';

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class QuickActionsService {
  static List<QuickAction> getQuickActions(BuildContext context) {
    if (!AppFeatureFlags.instance.areQuickActionsEnabled) {
      ConsoleLogger.info('[QuickActions] Disabled in this build');
      return [];
    }

    return [
      QuickAction(
        title: 'Ajouter un article',
        subtitle: 'Consommable ou durable',
        icon: Icons.add_shopping_cart,
        color: Colors.green,
        onTap: () {
          // TODO: Navigate to add item screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir dans le prochain sprint'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      QuickAction(
        title: 'Vérifier l\'inventaire',
        subtitle: 'Voir tous vos articles',
        icon: Icons.inventory,
        color: Colors.blue,
        onTap: () {
          // TODO: Navigate to inventory screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir dans le prochain sprint'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      QuickAction(
        title: 'Gérer le budget',
        subtitle: 'Suivre vos dépenses',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        onTap: () {
          // TODO: Navigate to budget screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir dans le prochain sprint'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      QuickAction(
        title: 'Paramètres',
        subtitle: 'Personnaliser l\'app',
        icon: Icons.settings,
        color: Colors.grey,
        onTap: () {
          // TODO: Navigate to settings screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir dans le prochain sprint'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];
  }
}
