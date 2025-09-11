import 'package:flutter/material.dart';

/// Service pour gérer la navigation et les routes de l'application
class NavigationService {
  /// Définition des routes et index pour tous les onglets
  /// index 0 pour dashboard (Accueil), 1 pour inventory (Inventaire), 
  /// 2 pour add-product (Ajouter), 3 pour budget (Budget), 4 pour settings (Paramètres)
  static const Map<int, String> tabRoutes = {
    0: '/dashboard',
    1: '/inventory', 
    2: '/add-product',
    3: '/budget',
    4: '/settings',
  };

  /// Obtenir l'index d'un onglet à partir de la route
  static int getTabIndexFromRoute(String route) {
    for (final entry in tabRoutes.entries) {
      if (entry.value == route) {
        return entry.key;
      }
    }
    return 0; // Default to dashboard
  }

  /// Obtenir la route à partir de l'index d'un onglet
  static String getRouteFromTabIndex(int index) {
    return tabRoutes[index] ?? '/dashboard';
  }

  /// Naviguer vers un onglet spécifique avec transitions fluides
  static void navigateToTab(BuildContext context, int index) {
    final route = getRouteFromTabIndex(index);
    
    // Utiliser pushReplacementNamed pour éviter l'accumulation de routes
    Navigator.pushReplacementNamed(context, route);
  }

  /// Vérifier si une route correspond à un onglet principal
  static bool isMainTabRoute(String route) {
    return tabRoutes.containsValue(route);
  }
}