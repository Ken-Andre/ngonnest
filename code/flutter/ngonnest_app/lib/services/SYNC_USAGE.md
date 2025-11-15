# Guide d'utilisation du SyncService

## Vue d'ensemble

Le `SyncService` implémente une synchronisation **offline-first** avec les principes suivants:
- ✅ **Local wins**: Les modifications locales sont prioritaires
- ✅ **File d'outbox**: Toutes les opérations sont enregistrées localement avant sync
- ✅ **Retry automatique**: Exponential backoff avec max 5 tentatives par opération
- ✅ **Sync optionnelle**: Nécessite le consentement explicite de l'utilisateur

## Architecture

```
┌─────────────────┐
│  User Action    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│ Apply Locally   │─────▶│  sync_outbox DB  │
└────────┬────────┘      └──────────────────┘
         │                        │
         │                        │ (when online + consent)
         ▼                        ▼
┌─────────────────┐      ┌──────────────────┐
│ Update UI       │      │  Background Sync │
└─────────────────┘      └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │  Remote API      │
                         │  (TODO: impl)    │
                         └──────────────────┘
```

## Utilisation de base

### 1. Initialisation

```dart
final syncService = SyncService();
await syncService.initialize();
```

### 2. Activer la synchronisation (avec consentement)

```dart
// Dans les paramètres de l'app
await syncService.enableSync(userConsent: true);
```

### 3. Enregistrer une opération locale

**Principe "local wins"**: Appliquez d'abord la modification localement, puis enregistrez-la pour sync:

```dart
// Exemple: Création d'un objet
final db = await DatabaseService().database;

// 1. Appliquer localement (local wins)
final objetId = await db.insert('objet', objetData);

// 2. Enregistrer pour sync ultérieure
await syncService.enqueueOperation(
  operationType: 'CREATE',
  entityType: 'objet',
  entityId: objetId,
  payload: objetData,
);
```

### 4. Types d'opérations supportées

```dart
// CREATE
await syncService.enqueueOperation(
  operationType: 'CREATE',
  entityType: 'objet',
  entityId: newId,
  payload: {'nom': 'Riz', 'quantite': 5},
);

// UPDATE
await syncService.enqueueOperation(
  operationType: 'UPDATE',
  entityType: 'objet',
  entityId: existingId,
  payload: {'quantite': 3},
);

// DELETE
await syncService.enqueueOperation(
  operationType: 'DELETE',
  entityType: 'objet',
  entityId: deletedId,
  payload: {'id': deletedId},
);
```

### 5. Entités supportées

- `objet` - Produits/objets du foyer
- `foyer` - Informations du foyer
- `reachat_log` - Historique des réachats
- `budget_categories` - Catégories budgétaires

## Synchronisation manuelle

```dart
// Dans un écran avec BuildContext
await syncService.forceSyncWithFeedback(context);
```

Cela affichera automatiquement des SnackBars pour:
- ✅ Synchronisation réussie
- ❌ Échec avec option de voir les détails
- ⚠️ Pas de connexion internet
- ⚠️ Sync désactivée

## Vérifier l'état de synchronisation

```dart
final status = syncService.getSyncStatus();

print('Sync activée: ${status['syncEnabled']}');
print('Consentement: ${status['userConsent']}');
print('En cours: ${status['isSyncing']}');
print('Opérations en attente: ${status['pendingOperations']}');
print('Opérations échouées: ${status['failedOperations']}');
print('Dernière sync: ${status['lastSyncTime']}');
```

## Écouter les changements

Le `SyncService` est un `ChangeNotifier`:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _syncService.addListener(_onSyncStateChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStateChanged);
    super.dispose();
  }

  void _onSyncStateChanged() {
    setState(() {
      // UI se met à jour automatiquement
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Opérations en attente: ${_syncService.pendingOperations}');
  }
}
```

## Intégration dans les repositories

### Exemple: InventoryRepository

```dart
class InventoryRepository {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();

  Future<int> createObjet(Map<String, dynamic> data) async {
    final database = await _db.database;
    
    // 1. Appliquer localement (local wins)
    final id = await database.insert('objet', data);
    
    // 2. Enregistrer pour sync
    await _sync.enqueueOperation(
      operationType: 'CREATE',
      entityType: 'objet',
      entityId: id,
      payload: data,
    );
    
    return id;
  }

  Future<void> updateObjet(int id, Map<String, dynamic> data) async {
    final database = await _db.database;
    
    // 1. Appliquer localement
    await database.update(
      'objet',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 2. Enregistrer pour sync
    await _sync.enqueueOperation(
      operationType: 'UPDATE',
      entityType: 'objet',
      entityId: id,
      payload: data,
    );
  }

  Future<void> deleteObjet(int id) async {
    final database = await _db.database;
    
    // 1. Appliquer localement
    await database.delete(
      'objet',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 2. Enregistrer pour sync
    await _sync.enqueueOperation(
      operationType: 'DELETE',
      entityType: 'objet',
      entityId: id,
      payload: {'id': id},
    );
  }
}
```

## Gestion des erreurs

Le service gère automatiquement:
- **Retry avec exponential backoff**: 2s, 4s, 8s...
- **Max 5 tentatives** par opération
- **Logging automatique** via `ErrorLoggerService`
- **Statut des opérations**: `pending`, `syncing`, `synced`, `failed`

Les opérations qui échouent après 5 tentatives restent en base avec `status='failed'` pour investigation.

## Nettoyage automatique

```dart
// Nettoie les opérations synchronisées > 30 jours
await syncService.cleanupSyncedOperations();
```

Appelez cette méthode périodiquement (ex: au démarrage de l'app).

## Synchronisation en arrière-plan

```dart
// Sync auto si:
// - Sync activée
// - Consentement donné
// - En ligne
// - Dernière sync > 30 min
await syncService.backgroundSync();
```

## TODO: Implémentation API

Actuellement, `_mockApiCall()` simule les appels API. Pour la production:

1. Créer un service API:
```dart
class ApiService {
  static const String baseUrl = 'https://api.ngonnest.com';
  
  Future<void> syncOperation(Map<String, dynamic> operation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/${operation['entity_type']}'),
      headers: {'Content-Type': 'application/json'},
      body: operation['payload'],
    );
    
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }
  }
}
```

2. Remplacer `_mockApiCall()` dans `sync_service.dart`:
```dart
Future<void> _syncOperation(Map<String, dynamic> operation) async {
  // ...
  try {
    await ApiService().syncOperation(operation);
    // ...
  }
}
```

## Résolution de conflits

**Stratégie actuelle**: "Local wins" (les modifications locales sont prioritaires)

Pour une résolution plus sophistiquée:
1. Ajouter `last_modified_at` à chaque entité
2. Comparer les timestamps lors de la sync
3. Implémenter une stratégie de merge si nécessaire

## Tests

```bash
# Lancer les tests du SyncService
flutter test test/services/sync_service_test.dart
```

Les tests couvrent:
- ✅ Initialisation
- ✅ Enqueue d'opérations
- ✅ Activation/désactivation
- ✅ Gestion d'erreurs
- ✅ Nettoyage

## Métriques et monitoring

Le service log automatiquement:
- Nombre d'opérations synchronisées
- Taux de succès/échec
- Durée de sync
- Erreurs rencontrées

Consultez `ErrorLoggerService` pour l'historique complet.
