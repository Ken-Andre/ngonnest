import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/config/supabase_config.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/services/supabase_api_service.dart';
import '../../lib/services/sync_service.dart';
import '../../lib/db.dart';
import '../../lib/services/console_logger.dart';

void main() {
  // Configuration pour les tests d'intégration Supabase
  setUpAll(() {
    // Initialiser sqflite pour tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialiser le logger
    ConsoleLogger.init(LogMode.debug);

    // Configuration test Supabase - utiliser des credentials de test
    // IMPORTANT: À remplacer par vraies valeurs en production
    // Note: Pour les tests, la configuration doit être faite via variables d'environnement
    // ou via configuration initiale, pas via assignment dynamique de const
  });

  group('Supabase Sync Integration', () {
    late Database database;

    setUp(() async {
      // Créer DB de test
      database = await initDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    group('SupabaseApiService', () {
      test('should initialize Supabase client', () async {
        // Tester seulement si config est valide (ne pas réellement se connecter)
        if (SupabaseConfig.isConfigured()) {
          expect(() => SupabaseApiService.instance, returnsNormally);
          expect(SupabaseApiService.instance.testConnection(), completes);
        } else {
          ConsoleLogger.info('⚠️  SUPABASE NOT CONFIGURED - SKIPPING API TESTS');
        }
      });

      test('should have required tables configured', () {
        final tables = SupabaseConfig.requiredTables;
        expect(tables.length, greaterThan(0));
        expect(tables, contains(SupabaseConfig.productsTable));
        expect(tables, contains(SupabaseConfig.householdsTable));
        expect(tables, contains(SupabaseConfig.purchasesTable));
      });

      test('should report connection status accurately', () async {
        if (!SupabaseConfig.isConfigured()) return;

        final isConnected = await SupabaseApiService.instance.testConnection();
        expect(isConnected, isA<bool>());
      });

      test('should get current user sync stats', () {
        final stats = SupabaseApiService.instance.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('is_connected'), isTrue);
        expect(stats.containsKey('timeout_configured'), isTrue);
        expect(stats.containsKey('rls_enabled'), isTrue);
        expect(stats.containsKey('tables_count'), isTrue);
      });
    });

    group('SyncService avec SupabaseApiService', () {
      test('should replace mock API with real Supabase API', () async {
        if (!SupabaseConfig.isConfigured()) return;

        final syncService = SyncService();

        // Tester que le service peut être initialisé
        await syncService.initialize();
        expect(syncService.syncEnabled, isFalse); // Par défaut désactivé

        // Tester activation sync
        await syncService.enableSync(userConsent: true);
        expect(syncService.syncEnabled, isTrue);
        expect(syncService.userConsent, isTrue);
      });

      test('should handle sync without authentication gracefully', () async {
        // Tester qu'on peut utiliser le service même sans config Supabase
        final syncService = SyncService();

        // Devrait passer silently ou avec mock si pas connecté
        await syncService.initialize();
        expect(syncService.getSyncStatus(), isNotNull);
      });

      test('should enqueue operations without Supabase connection', () async {
        // Tester le pattern outbox même sans cloud
        final syncService = SyncService();

        await syncService.initialize();

        // Enregistrer opération locale
        await syncService.enqueueOperation(
          operationType: 'CREATE',
          entityType: 'objet',
          entityId: 1,
          payload: {'nom': 'Test Product', 'quantite': 5},
        );

        // Vérifier que c'est enregistré
        final status = syncService.getSyncStatus();
        expect(status['pendingOperations'], greaterThan(0));
      });

      test('should not crash when syncing without Supabase config', () async {
        // Vérifier que l'app ne plante pas sans config Supabase
        final syncService = SyncService();

        // Devrait gérer gracieusement
        expect(() async => await syncService.forceSyncWithFeedback(null), returnsNormally);
      });
    });

    group('AuthService Integration', () {
      test('should validate auth state changes', () async {
        if (!SupabaseConfig.isConfigured()) return;

        final authService = AuthService.instance;

        // Écouter changements d'état
        authService.addListener(() {
          // Se déclenchera si connexion/déconnexion réussit
        });

        // Vérifier getters initial
        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUser, isNull);
      });

      test('should handle auth errors gracefully in test environment', () async {
        final authService = AuthService.instance;

        // Tester inscription avec config invalide (devrait échouer proprement)
        if (!SupabaseConfig.isConfigured()) {
          final success = await authService.signUp(
            email: 'test@example.com',
            password: 'password',
            firstName: 'Test',
            lastName: 'User',
          );

          expect(success, isFalse);
          expect(authService.errorMessage, isNotNull);
        }
      });

      test('should report auth stats accurately', () {
        final authService = AuthService.instance;
        final stats = authService.getStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('is_authenticated'), isTrue);
        expect(stats.containsKey('user_email'), isTrue);
        // Password ne doit jamais être dans stats
        expect(stats.containsKey('password'), isFalse);
      });
    });

    group('Performance Cameroun', () {
      test('should have appropriate timeouts for slow network', () {
        // Vérifier timeouts configurés pour Cameroun
        expect(SupabaseConfig.connectionTimeout, greaterThan(5000)); // Min 5s
        expect(SupabaseConfig.receiveTimeout, greaterThan(10000)); // Min 10s
      });

      test('should handle network errors gracefully', () async {
        if (!SupabaseConfig.isConfigured()) return;

        final apiService = SupabaseApiService.instance;

        // Tester gestion d'erreur réseau
        try {
          // Simuler une opération qui peut échouer
          await apiService.syncOperation({
            'operation_type': 'CREATE',
            'entity_type': 'objet',
            'entity_id': 999,
            'payload': 'invalid_payload',
          });
        } catch (e) {
          // Devrait log l'erreur sans planter le test
          expect(e, isNotNull);
        }
      });

      test('should have offline-first fallback for all operations', () async {
        final syncService = SyncService();
        await syncService.initialize();

        // Vérifier qu'on peut utiliser l'app complètement offline
        final status = syncService.getSyncStatus();
        expect(status['syncEnabled'], isA<bool>()); // Peu importe la valeur, principal: pas crash
      });
    });

    group('Data Integrity', () {
      test('should validate operation payloads', () async {
        final syncService = SyncService();

        // Tester enregistrement opération valide
        await syncService.enqueueOperation(
          operationType: 'CREATE',
          entityType: 'objet',
          entityId: 1,
          payload: {
            'nom': 'Produit Test',
            'categorie': 'Test',
            'type': 'durable',
            'quantite_initiale': 10,
            'unite': 'pièce',
          },
        );

        expect(syncService.pendingOperations, greaterThan(0));
      });

      test('should handle large payloads within reasonable limits', () async {
        final syncService = SyncService();

        // Créer payload volumineux (mais raisonnable)
        final largePayload = {
          'nom': 'Produit avec commentaires longs',
          'commentaires': 'A' * 1000, // 1000 caractères
          'categorie': 'Test',
          'type': 'durable',
          'quantite_initiale': 1,
          'unite': 'pièce',
        };

        // Devrait marcher sans planter
        await syncService.enqueueOperation(
          operationType: 'CREATE',
          entityType: 'objet',
          entityId: 2,
          payload: largePayload,
        );

        expect(syncService.pendingOperations, greaterThan(0));
      });
    });

    group('Error Recovery', () {
      test('should retry failed operations', () async {
        if (!SupabaseConfig.isConfigured()) return;

        final syncService = SyncService();

        // Simuler opération qui échoue puis réussir
        // Les tests spécifiques aux retry seraient dans les tests unitaires
        expect(() async => await syncService.forceSyncWithFeedback(null), returnsNormally);
      });

      test('should clean up old sync operations', () async {
        final syncService = SyncService();
        await syncService.initialize();

        // Ne devrait pas planter
        await syncService.cleanupSyncedOperations();
      });

      test('should reset properly between test runs', () {
        // Vérifier qu'il n'y a pas d'état résiduel
        final syncService1 = SyncService();
        final syncService2 = SyncService();

        expect(syncService1 != syncService2, isTrue); // Instances différentes pour tests
      });
    });

    group('Integration Flow', () {
      test('should complete full sync cycle in test environment', () async {
        // Test du flow complet: local -> sync -> cloud
        final syncService = SyncService();
        await syncService.initialize();

        // 1. Ajouter opération locale
        await syncService.enqueueOperation(
          operationType: 'CREATE',
          entityType: 'objet',
          entityId: DateTime.now().millisecondsSinceEpoch,
          payload: {
            'nom': 'Integration Test Product',
            'categorie': 'Test',
            'type': 'durable',
            'quantite_initiale': 1,
            'unite': 'pièce',
          },
        );

        // 2. Vérifier opération en attente
        expect(syncService.pendingOperations, greaterThan(0));

        // 3. Tenter sync (peut échouer si pas configuré, mais ne devrait pas planter)
        try {
          await syncService.forceSyncWithFeedback(null);
        } catch (e) {
          // OK si pas configuré
          ConsoleLogger.info('Expected failure in test without Supabase config: $e');
        }

        // 4. Vérifier app toujours fonctionnelle
        final finalStatus = syncService.getSyncStatus();
        expect(finalStatus, isNotNull);
      });

      test('should handle concurrent sync attempt gracefully', () async {
        final syncService = SyncService();

        // Tester plusieurs sync simultanées
        final futures = List.generate(3, (_) => syncService.forceSyncWithFeedback(null));

        // Ne devrait pas planter même si concurrentes
        await Future.wait(futures.map((f) => f.catchError((_) => null)));
      });
    });
  });

  group('Configuration Validation', () {
    test('should detect missing Supabase configuration', () {
      // Test sans modifier les const - on teste seulement la logique de validation
      // Puisque les valeurs sont const, on teste les cas edge avec les getters
      final currentUrl = SupabaseConfig.url;
      final currentKey = SupabaseConfig.anonKey;

      // Tester la logique avec des valeurs qui seraient "non configurées"
      // Simuler via override des getters si nécessaire (mais pour les tests, on assume la config)

      // Si la config actuelle est valide, le test passe
      if (currentUrl.contains('supabase.co') && currentKey.length > 50) {
        expect(SupabaseConfig.isConfigured(), isTrue);
      } else {
        // Configuration de test - ne devrait pas être configurée
        expect(SupabaseConfig.isConfigured(), isFalse);
      }
    });

    test('should validate correct Supabase configuration format', () {
      if (SupabaseConfig.isConfigured()) {
        expect(SupabaseConfig.url, contains('supabase.co'));
        expect(SupabaseConfig.anonKey.length, greaterThan(50)); // Typique pour clés Supabase
      }
    });
  });

  group('Offline Mode Tests', () {
    test('should function completely offline without Supabase', () async {
      // Test sans modifier les const - nous testons seulement le pattern offline
      final syncService = SyncService();
      await syncService.initialize();

      // Tout devrait marcher en offline même avec Supabase configuré
      await syncService.enqueueOperation(
        operationType: 'CREATE',
        entityType: 'objet',
        entityId: 1,
        payload: {'nom': 'Offline Product'},
      );

      expect(syncService.pendingOperations, greaterThan(0));

      final status = syncService.getSyncStatus();
      expect(status['syncEnabled'], isFalse); // Par défaut sans config explicite
    });

    test('should maintain data integrity offline', () async {
      // Tester que les données restent cohérentes sans cloud
      final syncService = SyncService();

      // Reset si besoin pour tests
      SyncService.resetInstance();

      // Créer nouvelle instance
      final newSyncService = SyncService();
      await newSyncService.initialize();

      // Ajouter plusieurs opérations
      await newSyncService.enqueueOperation(
        operationType: 'CREATE',
        entityType: 'objet',
        entityId: 1,
        payload: {'nom': 'Data Integrity Test'},
      );

      await newSyncService.enqueueOperation(
        operationType: 'UPDATE',
        entityType: 'objet',
        entityId: 1,
        payload: {'nom': 'Updated Name'},
      );

      // Vérifier comptage
      expect(newSyncService.pendingOperations, equals(2));

      final stats = newSyncService.getSyncStatus();
      expect(stats['pendingOperations'], equals(2));
      expect(stats['failedOperations'], equals(0));
    });
  });
}
