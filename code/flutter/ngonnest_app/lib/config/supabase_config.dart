import 'package:flutter/foundation.dart';

/// Configuration Supabase pour NgonNest
/// Respects les règles Cameroun: offline-first, performance <25Mo, Android 8.0+
class SupabaseConfig {
  // Configuration prod - À remplacer par vos vraies valeurs Supabase
  static const String prod_url = 'https://twihbdmgqrsvfpyuhkoz.supabase.co';
  static const String prod_anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3aWhiZG1ncXJzdmZweXVoa296Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzkwODMsImV4cCI6MjA3NzUxNTA4M30.cs-oGVwYA3NNcH60VU8qtFX7M3GqXMB6mITZZJfOT7Y';

  // Configuration dev pour tests
  static const String dev_url = 'https://twihbdmgqrsvfpyuhkoz.supabase.co';
  static const String dev_anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3aWhiZG1ncXJzdmZweXVoa296Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzkwODMsImV4cCI6MjA3NzUxNTA4M30.cs-oGVwYA3NNcH60VU8qtFX7M3GqXMB6mITZZJfOT7Y';

  // Utilise la config selon le mode (kReleaseMode pour production)
  static String get url => kReleaseMode ? prod_url : dev_url;
  static String get anonKey => kReleaseMode ? prod_anonKey : dev_anonKey;

  // Timeouts optimisés pour le Cameroun (réseau souvent lent)
  static const int connectionTimeout = 10000; // 10 secondes
  static const int receiveTimeout = 15000; // 15 secondes

  // Real-time configuration pour sync bidirectionnelle
  static const String realtimeUrl =
      'wss://realtime.supabase.co/socket/websocket';

  // Tables Supabase (mêmes noms que locaux pour cohérence)
  static const String profilesTable = 'profiles';
  static const String householdsTable = 'households';
  static const String productsTable = 'products';
  static const String purchasesTable = 'purchases';
  static const String budgetCategoriesTable = 'budget_categories';
  static const String notificationsTable = 'notifications';

  // RLS Policies existantes sur Supabase (doivent être synchronisées)
  static const bool rlsEnabled = true;

  /// Validation de la configuration
  static bool isConfigured() {
    return url.isNotEmpty && !url.contains('YOUR_SUPABASE') &&
        anonKey.isNotEmpty && !anonKey.contains('YOUR_SUPABASE');
  }

  /// Validation des tables requises
  static List<String> get requiredTables => [
    profilesTable,
    householdsTable,
    productsTable,
    purchasesTable,
    budgetCategoriesTable,
    notificationsTable,
  ];
}
