import 'package:flutter/foundation.dart';

/// Service de gestion des feature flags
/// Permet d'activer/désactiver des fonctionnalités selon l'environnement
class AppFeatureFlags {
  static AppFeatureFlags? _instance;
  
  static AppFeatureFlags get instance {
    _instance ??= AppFeatureFlags._internal();
    return _instance!;
  }
  
  AppFeatureFlags._internal();
  
  /// Sync cloud uniquement disponible en debug mode ou profile mode
  /// En release (production), cette fonctionnalité sera désactivée
  bool get isCloudSyncEnabled => kDebugMode || kProfileMode;
  
  /// Premium features (désactivé pour le moment dans toutes les versions)
  bool get isPremiumEnabled => false;
  
  /// Quick actions (désactivé pour le moment, à activer une fois implémentées)
  bool get areQuickActionsEnabled => false;
  
  /// Savings tips (désactivé pour le moment, à activer quand données validées)
  bool get areSavingsTipsEnabled => false;
  
  /// Liste de toutes les features flags pour debugging
  Map<String, bool> getAllFlags() => {
    'cloudSync': isCloudSyncEnabled,
    'premium': isPremiumEnabled,
    'quickActions': areQuickActionsEnabled,
    'savingsTips': areSavingsTipsEnabled,
  };
}
