# NGONNEST – TASKS V1 (MVP OFFLINE-ONLY)

> Ce fichier contient UNIQUEMENT les tâches V1 MVP.
> Pour V2/V3, voir `tasks_v2.md` et `tasks_v3_future.md`.
> Toutes les tâches respectent AI_RULES.md et requirements.md (V1.*).

## 0. Règles de Validation des Tâches

Une tâche est **DONE** uniquement si :

### F2P (False-to-Positive Check)
- Le code fait RÉELLEMENT ce qui est décrit (pas de faux positif).
- Vérification manuelle fonctionnelle.
- "Le test est-il vraiment vert pour la BONNE raison ?"

### P2F (Pass-to-Fail Check)
- `flutter test` passe à 100% (unit + widget + integration concernés).
- Aucun test cassé par la modification.
- Si un test casse, la PR est BLOQUÉE jusqu'à correction.

---

## Phase 1: Fondations Critiques (Semaines 1-3)

### Task 1.1: Sécurité & Configuration Environnement

**Liée à** : Requirement V1.1 (Security and Configuration Management)

- [ ] **1.1.1** Installer et configurer `flutter_dotenv`
  - Ajouter `flutter_dotenv: ^5.1.0` dans `pubspec.yaml`
  - Exécuter `flutter pub get`
  - Créer `.env.example` avec clés vides (`SUPABASE_URL=`, `SUPABASE_ANON_KEY=`)
  - Ajouter `.env` dans `.gitignore` (vérifier qu'il n'est pas tracké)
  - Créer `.env.dev` et `.env.prod` (non commités, locaux uniquement)
  - Tester le chargement avec `await dotenv.load()` dans `main.dart`

- [ ] **1.1.2** Créer service de configuration sécurisé
  - Créer fichier `lib/config/env_config.dart`
  - Implémenter getter `static String supabaseUrl` via `dotenv.env['SUPABASE_URL'] ?? ''`
  - Implémenter getter `static String supabaseAnonKey` via `dotenv.env['SUPABASE_ANON_KEY'] ?? ''`
  - Ajouter validation : lever `StateError` si clé manquante au runtime
  - Documenter chaque méthode avec `///` docstrings

- [ ] **1.1.3** Migrer toutes les références hardcodées
  - Utiliser `grep -r "supabase" lib/` pour trouver toutes les occurrences
  - Remplacer toutes les URLs/clés hardcodées par `EnvConfig.supabaseUrl` / `.supabaseAnonKey`
  - Vérifier dans `AuthService`, `SyncService`, etc.
  - Compiler et valider que l'app démarre sans erreur

- [ ] **1.1.4** Configurer obfuscation pour release builds
  - Modifier scripts de build pour inclure `--obfuscate --split-debug-info=build/app/outputs/symbols`
  - Tester build release Android : `flutter build apk --release --obfuscate`
  - Tester build release iOS : `flutter build ios --release --obfuscate`
  - Vérifier que symbols sont générés dans `build/app/outputs/symbols`
  - Documenter dans `README.md` section "Building for Production"

#### Tests pour Task 1.1

- [ ] **Test 1.1.T1** : Unit test `EnvConfig` - lance exception si `.env` manque
  - Créer `test/config/env_config_test.dart`
  - Tester que `EnvConfig.supabaseUrl` lance `StateError` si variable absente
  - Tester que valeurs correctes sont retournées si `.env` présent

- [ ] **Test 1.1.T2** : Build release Android réussit sans erreur
  - Exécuter `flutter build apk --release --obfuscate`
  - Vérifier exit code = 0
  - Installer APK sur device test et lancer app

- [ ] **Test 1.1.T3** : Build release iOS réussit sans erreur
  - Exécuter `flutter build ios --release --obfuscate`
  - Vérifier exit code = 0

- [ ] **Test 1.1.T4** : Décompiler APK et vérifier absence clés (manuel)
  - Utiliser `jadx` ou similaire
  - Rechercher strings "supabase", "anon", "key"
  - Confirmer qu'aucune clé sensible n'apparaît en clair

- [ ] **F2P Check** : L'app fonctionne avec `.env.dev` et `.env.prod` distincts
  - Tester avec différentes valeurs dans chaque fichier
  - Vérifier comportement correct selon environnement

- [ ] **P2F Check** : `flutter test` passe à 100%
  - Exécuter `flutter test`
  - Tous les tests existants + nouveaux doivent passer

---

### Task 1.2: Feature Flags Service

**Liée à** : Requirement V1.2 (Feature Flags System)

- [ ] **1.2.1** Créer `FeatureFlagService` de base
  - Créer fichier `lib/services/feature_flag_service.dart`
  - Implémenter classe `FeatureFlagService`
  - Ajouter méthode `bool isCloudSyncEnabled()`
  - Ajouter méthode `bool isPremiumEnabled()`
  - Ajouter méthode `bool isExperimentalFeaturesEnabled()`
  - Retourner `false` en dur pour V1 (documenter avec `// V1: disabled in production`)

- [ ] **1.2.2** Détecter environnement (dev vs prod)
  - Importer `package:flutter/foundation.dart`
  - Ajouter getter `bool get isDevMode => kDebugMode || kProfileMode`
  - Modifier `isCloudSyncEnabled` : retourner `isDevMode` (true en dev, false en release)
  - Documenter comportement dans docstring
  - Tester avec `flutter run --release` pour vérifier

- [ ] **1.2.3** Intégrer dans Provider
  - Dans `main.dart`, ajouter `Provider<FeatureFlagService>(create: (_) => FeatureFlagService())`
  - Rendre accessible via `context.read<FeatureFlagService>()`
  - Tester injection dans `SettingsScreen` avec `final flags = context.watch<FeatureFlagService>();`

- [ ] **1.2.4** Modifier UI Settings pour désactiver sync
  - Dans `lib/screens/settings_screen.dart`, récupérer `FeatureFlagService`
  - Wrapper bouton sync avec condition : `if (flags.isCloudSyncEnabled()) {...} else {greyedButton}`
  - Si désactivé, griser le bouton avec `onPressed: null`
  - Ajouter `Tooltip` avec message "Fonctionnalité bientôt disponible"
  - Empêcher tout appel à `SyncService` si flag = false

#### Tests pour Task 1.2

- [ ] **Test 1.2.T1** : Unit test `FeatureFlagService.isCloudSyncEnabled()` retourne false en release
  - Créer `test/services/feature_flag_service_test.dart`
  - Mocker `kDebugMode = false`
  - Tester que `isCloudSyncEnabled()` retourne `false`

- [ ] **Test 1.2.T2** : Unit test `isCloudSyncEnabled()` retourne true en debug
  - Mocker `kDebugMode = true`
  - Tester que `isCloudSyncEnabled()` retourne `true`

- [ ] **Test 1.2.T3** : Widget test `SettingsScreen` affiche bouton grisé en release
  - Créer `test/screens/settings_screen_test.dart`
  - Mocker `FeatureFlagService` avec `isCloudSyncEnabled = false`
  - Vérifier que bouton sync a `onPressed: null`
  - Vérifier présence du Tooltip

- [ ] **Test 1.2.T4** : Integration test - tap sur sync désactivé ne déclenche rien
  - Créer test d'intégration
  - Tapper sur bouton sync quand désactivé
  - Vérifier qu'aucun appel à `SyncService` n'est fait (spy/mock)

- [ ] **F2P Check** : En mode release, impossible d'activer le sync manuellement
  - Builder en release : `flutter build apk --release`
  - Installer et tester : bouton doit être gris et non cliquable

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 1.3: Persistence des États d'Alertes

**Liée à** : Requirement V1.3 (Alert Persistence System)

- [ ] **1.3.1** Concevoir schéma SQL `alert_states`
  - Créer fichier de migration `docs/migrations/0012_alert_states.sql` (documentation)
  - Définir table : `CREATE TABLE alert_states (id INTEGER PRIMARY KEY, alert_id TEXT UNIQUE, is_read INTEGER DEFAULT 0, is_resolved INTEGER DEFAULT 0, updated_at TEXT)`
  - Ajouter index : `CREATE INDEX idx_alert_states_alert_id ON alert_states(alert_id)`
  - Documenter avec commentaires SQL

- [ ] **1.3.2** Implémenter migration dans `DatabaseService`
  - Ouvrir `lib/services/database_service.dart`
  - Incrémenter `_databaseVersion` à 12
  - Dans `_onCreate` ou `_onUpgrade`, ajouter migration 0012
  - Implémenter méthode `_createAlertStatesTable(Database db)` avec SQL du 1.3.1
  - Tester migration sur base vide (nouvelle install)
  - Tester migration sur base existante (upgrade depuis v11)

- [ ] **1.3.3** Créer modèle `AlertState`
  - Créer fichier `lib/models/alert_state.dart`
  - Définir classe avec champs : `String alertId`, `bool isRead`, `bool isResolved`, `DateTime updatedAt`
  - Implémenter `Map<String, dynamic> toMap()` pour sérialisation SQLite
  - Implémenter `factory AlertState.fromMap(Map<String, dynamic> map)` pour désérialisation
  - Implémenter `AlertState copyWith({...})` pour modifications immutables
  - Ajouter `@override String toString()` pour debug

- [ ] **1.3.4** Implémenter Repository `AlertStateRepository`
  - Créer fichier `lib/repository/alert_state_repository.dart`
  - Injecter `DatabaseService` via constructeur
  - Méthode `Future<void> saveAlertState(AlertState state)` utilisant `INSERT OR REPLACE`
  - Méthode `Future<AlertState?> getAlertState(String alertId)` avec query paramétrisée
  - Méthode `Future<Map<String, AlertState>> getAllAlertStates()` retournant Map alertId -> state
  - Gestion d'erreurs avec try/catch et logging via `ErrorLoggerService`

- [ ] **1.3.5** Intégrer dans `AlertService`
  - Ouvrir `lib/services/alert_service.dart`
  - Injecter `AlertStateRepository` via constructeur
  - Ajouter méthode `Future<void> markAlertAsRead(String alertId)`
  - Ajouter méthode `Future<void> markAlertAsResolved(String alertId)`
  - Au chargement des alertes (méthode `getAlerts()`), fusionner avec états via `await _alertStateRepo.getAllAlertStates()`
  - Implémenter logique : si alerte marquée lue, ne plus notifier

- [ ] **1.3.6** UI feedback pour changements d'état
  - Dans liste des alertes (`AlertListWidget` ou écran alertes), afficher icône différente si `isRead`
  - Utiliser `Icon(Icons.visibility_off)` pour alertes lues
  - Utiliser `Icon(Icons.check_circle)` pour alertes résolues
  - Ajouter animation `FadeTransition` quand alerte devient résolue
  - Tester visuellement avec 10, 50, 100+ alertes

#### Tests pour Task 1.3

- [ ] **Test 1.3.T1** : Unit test migration `0012_alert_states` sur base vide
  - Créer `test/services/database_service_test.dart`
  - Initialiser DB avec version 12
  - Vérifier que table `alert_states` existe
  - Vérifier que index `idx_alert_states_alert_id` existe

- [ ] **Test 1.3.T2** : Unit test migration upgrade depuis v11 vers v12
  - Créer DB avec version 11
  - Upgrader vers version 12
  - Vérifier que table `alert_states` est créée correctement

- [ ] **Test 1.3.T3** : Unit test `AlertStateRepository.saveAlertState()` fonctionne
  - Créer `test/repository/alert_state_repository_test.dart`
  - Insérer un `AlertState`
  - Vérifier qu'il est sauvegardé en DB

- [ ] **Test 1.3.T4** : Unit test `AlertStateRepository.getAlertState()` retourne bon état
  - Sauvegarder un état
  - Récupérer avec `getAlertState()`
  - Vérifier valeurs correctes

- [ ] **Test 1.3.T5** : Integration test - marquer alerte lue, redémarrer app, vérifier persistance
  - Créer integration test
  - Marquer alerte comme lue
  - Simuler redémarrage (recharger AlertService)
  - Vérifier que alerte est toujours marquée lue

- [ ] **Test 1.3.T6** : Performance test - 1000 alertes chargées en <2s
  - Créer dataset de 1000 alertes
  - Mesurer temps de chargement avec `Stopwatch`
  - Assert temps < 2000ms

- [ ] **F2P Check** : Une alerte marquée lue ne réapparaît jamais comme "non lue"
  - Test manuel : marquer alerte lue → redémarrer app → vérifier état

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 1.4: Inventaire CRUD Complet Offline

**Liée à** : Requirement V1.4 (Offline Inventory Management)

- [ ] **1.4.1** Audit CRUD existant
  - Ouvrir `lib/repository/inventory_repository.dart`
  - Vérifier méthode `addProduct(Product product)` : persiste-t-elle vraiment en SQLite ?
  - Vérifier méthode `updateProduct(Product product)` : UPDATE SQL correct ?
  - Vérifier méthode `deleteProduct(String id)` : DELETE SQL correct ?
  - Identifier tout code "fake" (données stockées uniquement en mémoire)
  - Documenter findings dans commentaire ou issue

- [ ] **1.4.2** Corriger `addProduct` si nécessaire
  - S'assurer que `addProduct` utilise `db.insert()` sur table `products`
  - Retourner l'ID du produit créé (via `LAST_INSERT_ROWID()` ou retour de `insert()`)
  - Ajouter validation : `assert(product.name.isNotEmpty)`, `assert(product.quantity > 0)`
  - Gérer erreurs SQLite (contraintes, unicité) avec try/catch
  - Logger erreurs via `ErrorLoggerService.log()`

- [ ] **1.4.3** Corriger `updateProduct` si nécessaire
  - Implémenter avec `db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id])`
  - Valider que l'ID existe avant update (query count)
  - Retourner `Future<bool>` : true si succès, false si échec
  - Tester modification de chaque champ individuellement

- [ ] **1.4.4** Corriger `deleteProduct` si nécessaire
  - Implémenter avec `db.delete('products', where: 'id = ?', whereArgs: [id])`
  - Vérifier dépendances : alertes liées, budgets liés (décider strategy: cascade ou prevent)
  - Implémenter soft-delete OU hard-delete (documenter choix dans code)
  - Dans UI, ajouter `AlertDialog` de confirmation avant suppression

- [ ] **1.4.5** Implémenter recherche SQLite
  - Créer méthode `Future<List<Product>> searchProducts(String query)` dans repository
  - Utiliser `db.query('products', where: 'name LIKE ?', whereArgs: ['%$query%'])`
  - Limiter résultats à 100 par défaut avec `limit: 100`
  - Retourner `List<Product>` depuis résultats Map
  - Tester performance avec dataset de 500+ produits

- [ ] **1.4.6** Tester persistance après redémarrage
  - Test manuel :
    1. Ajouter un produit "Test Product"
    2. Fermer app complètement (kill process)
    3. Redémarrer app
    4. Vérifier que "Test Product" est toujours dans inventaire
  - Documenter résultat du test

#### Tests pour Task 1.4

- [ ] **Test 1.4.T1** : Unit test `addProduct()` insère bien en DB
  - Créer `test/repository/inventory_repository_test.dart`
  - Appeler `addProduct()` avec produit test
  - Vérifier via query directe que produit existe en DB

- [ ] **Test 1.4.T2** : Unit test `updateProduct()` modifie le bon produit
  - Insérer produit
  - Modifier un champ (ex: quantité)
  - Appeler `updateProduct()`
  - Vérifier via query que modification est persistée

- [ ] **Test 1.4.T3** : Unit test `deleteProduct()` supprime correctement
  - Insérer produit
  - Appeler `deleteProduct()`
  - Vérifier via query que produit n'existe plus

- [ ] **Test 1.4.T4** : Unit test `searchProducts()` retourne résultats pertinents
  - Insérer 10 produits (5 avec "Rice", 5 avec "Beans")
  - Rechercher "Rice"
  - Vérifier que 5 résultats retournés

- [ ] **Test 1.4.T5** : Integration test - CRUD complet sur 1 produit
  - Add → vérifier présence
  - Update → vérifier modification
  - Delete → vérifier suppression

- [ ] **Test 1.4.T6** : Performance test - recherche sur 500 produits en <1s
  - Insérer 500 produits
  - Mesurer temps de `searchProducts()`
  - Assert < 1000ms

- [ ] **F2P Check** : Données persistent après redémarrage app (test manuel)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 2: Budget & Prix (Semaines 4-5)

### Task 2.1: Budget Basique Offline

**Liée à** : Requirement V1.5 (Basic Budget Management)

- [ ] **2.1.1** Créer/valider table budget SQLite
  - Vérifier dans `DatabaseService` que table `budgets` existe
  - Schéma requis : `id INTEGER PRIMARY KEY, household_id INTEGER, monthly_limit REAL, month INTEGER, year INTEGER`
  - Si manquante, créer migration
  - Ajouter index : `CREATE INDEX idx_budgets_household_month_year ON budgets(household_id, month, year)`

- [ ] **2.1.2** Implémenter `BudgetRepository.setBudget()`
  - Créer/ouvrir `lib/repository/budget_repository.dart`
  - Méthode `Future<void> setBudget(int householdId, double monthlyLimit, int month, int year)`
  - Utiliser `INSERT OR REPLACE INTO budgets ...`
  - Valider `monthlyLimit > 0` avec assert
  - Gérer erreurs avec try/catch

- [ ] **2.1.3** Implémenter calcul des dépenses
  - Méthode `Future<double> getTotalSpent(int householdId, int month, int year)`
  - Joindre avec table `products` ou `purchases` (selon modèle de données)
  - SQL : `SELECT SUM(price * quantity) FROM products WHERE household_id = ? AND month = ? AND year = ?`
  - Retourner 0.0 si aucun produit
  - Optimiser requête (vérifier EXPLAIN QUERY PLAN)

- [ ] **2.1.4** Implémenter vue budget simple
  - Dans `lib/screens/budget_screen.dart`, charger budget via `BudgetRepository`
  - Afficher 3 chiffres clés :
    - Budget total (ex: 50,000 FCFA)
    - Dépensé (ex: 35,000 FCFA)
    - Reste (Budget - Dépensé)
  - Calculer % consommé : `(spent / budget) * 100`
  - Afficher barre de progression avec `LinearProgressIndicator`
  - Couleur conditionnelle :
    - Vert si % < 70%
    - Orange si 70% ≤ % < 90%
    - Rouge si % ≥ 90%

- [ ] **2.1.5** Implémenter alertes budget
  - Dans `BudgetService`, méthode `checkBudgetAlerts()`
  - Si % > 90%, créer alerte "Attention : 90% du budget atteint"
  - Si % > 100%, créer alerte "Budget dépassé !"
  - Persister alertes dans `alert_states` (via `AlertService`)
  - Afficher en haut du dashboard (widget `BudgetAlertBanner`)

#### Tests pour Task 2.1

- [ ] **Test 2.1.T1** : Unit test `setBudget()` enregistre bien le budget
  - Créer `test/repository/budget_repository_test.dart`
  - Appeler `setBudget(1, 50000, 12, 2025)`
  - Query directe pour vérifier

- [ ] **Test 2.1.T2** : Unit test `getTotalSpent()` calcule correctement
  - Insérer 3 produits avec prix
  - Appeler `getTotalSpent()`
  - Vérifier somme correcte

- [ ] **Test 2.1.T3** : Widget test `BudgetScreen` affiche les bonnes valeurs
  - Mocker `BudgetRepository` avec données test
  - Vérifier présence des 3 valeurs (budget, spent, remaining)

- [ ] **Test 2.1.T4** : Integration test - dépasser 90% déclenche alerte
  - Définir budget 10000
  - Ajouter produits totalisant 9500
  - Vérifier alerte "90%" créée

- [ ] **Test 2.1.T5** : Integration test - dépasser 100% déclenche alerte
  - Définir budget 10000
  - Ajouter produits totalisant 11000
  - Vérifier alerte "dépassé" créée

- [ ] **F2P Check** : Budget et dépenses corrects après ajout de 10 produits

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 2.2: Prix Locaux & RegionConfig

**Liée à** : Requirement V1.6 (Price Database)

- [ ] **2.2.1** Créer classe `RegionConfig`
  - Créer fichier `lib/config/region_config.dart`
  - Définir classe avec champs : `String countryCode`, `String currencyCode`, `String currencySymbol`
  - Méthode statique `RegionConfig detect()` :
    - Importer `package:intl/intl.dart`
    - Détecter via `Intl.systemLocale` ou `Platform.localeName`
    - Parser pour extraire code pays (ex: "fr_CM" → "CM")
  - Fallback sur Cameroun si détection échoue : `return RegionConfig('CM', 'XAF', 'FCFA')`

- [ ] **2.2.2** Implémenter support multi-devises
  - Créer Map statique des régions supportées :
    ```dart
    static const regions = {
      'CM': RegionConfig('CM', 'XAF', 'FCFA'),
      'NG': RegionConfig('NG', 'NGN', '₦'),
      'CI': RegionConfig('CI', 'XOF', 'FCFA'),
    };
    ```
  - Méthode `String formatPrice(double amount, RegionConfig region)` :
    - Retourner `"${amount.toStringAsFixed(0)} ${region.currencySymbol}"`
  - Tester avec Cameroun (FCFA) et Nigeria (₦)

- [ ] **2.2.3** Charger base de prix Cameroun
  - Créer fichier `assets/data/cameroon_prices.json`
  - Format JSON :
    ```json
    [
      {"category": "Légumes", "product": "Tomate", "price": 500, "unit": "kg", "source": "Mahima Douala", "updated": "2025-12-01"},
      {"category": "Céréales", "product": "Riz", "price": 1200, "unit": "kg", "source": "Casino Douala", "updated": "2025-12-01"}
    ]
    ```
  - Ajouter asset dans `pubspec.yaml` : `assets: - assets/data/cameroon_prices.json`
  - Au démarrage app, charger avec `rootBundle.loadString('assets/data/cameroon_prices.json')`
  - Parser JSON et stocker dans table SQLite `prices` (créer si nécessaire)

- [ ] **2.2.4** Créer service `PriceService`
  - Créer `lib/services/price_service.dart`
  - Méthode `Future<double?> getAveragePrice(String category, String product)`
    - Query SQLite : `SELECT AVG(price) FROM prices WHERE category = ? AND product = ?`
    - Retourner null si aucun prix trouvé
  - Méthode `Future<void> updatePrice(String product, double price, String source)`
    - INSERT OR UPDATE prix dans table
  - Exposer via Provider dans `main.dart`

- [ ] **2.2.5** Intégrer prix dans formulaire ajout produit
  - Dans `AddProductScreen`, quand catégorie et produit sélectionnés :
    - Appeler `PriceService.getAveragePrice(category, product)`
    - Si prix trouvé, pré-remplir champ prix avec suggestion
    - Permettre modification manuelle par utilisateur
  - Enregistrer prix saisi si différent du prix moyen

#### Tests pour Task 2.2

- [ ] **Test 2.2.T1** : Unit test `RegionConfig.detect()` retourne bon pays
  - Mocker `Intl.systemLocale`
  - Tester avec "fr_CM" → attend "CM"
  - Tester avec locale inconnue → attend "CM" (fallback)

- [ ] **Test 2.2.T2** : Unit test `formatPrice()` formate correctement XAF et NGN
  - Tester `formatPrice(1500, RegionConfig.CM)` → "1500 FCFA"
  - Tester `formatPrice(1500, RegionConfig.NG)` → "1500 ₦"

- [ ] **Test 2.2.T3** : Unit test chargement `cameroon_prices.json` réussit
  - Créer test avec asset factice
  - Vérifier parsing JSON sans erreur

- [ ] **Test 2.2.T4** : Unit test `PriceService.getAveragePrice()` retourne prix correct
  - Insérer 3 prix pour "Tomate"
  - Appeler `getAveragePrice("Légumes", "Tomate")`
  - Vérifier moyenne correcte

- [ ] **Test 2.2.T5** : Widget test formulaire suggère bon prix
  - Sélectionner catégorie "Légumes" + produit "Tomate"
  - Vérifier que champ prix est pré-rempli

- [ ] **F2P Check** : Prix affichés sont réalistes pour Cameroun (vérif manuelle)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 3: UX & Navigation (Semaines 6-7)

### Task 3.1: Onboarding Simple

**Liée à** : Requirement V1.7 (Simple Onboarding Flow)

- [ ] **3.1.1** Créer écran OnboardingScreen
  - Créer `lib/screens/onboarding_screen.dart`
  - Utiliser `PageView.builder` pour slides
  - Définir 3-4 slides : Bienvenue, Inventaire, Budget, Alertes
  - Ajouter `PageController` pour navigation

- [ ] **3.1.2** Slide 1 : Bienvenue
  - Titre : "Bienvenue sur NgonNest"
  - Illustration : asset image ou `Icon(Icons.home, size: 100)`
  - Texte : "Gérez votre maison intelligemment"
  - Bouton "Suivant" en bas

- [ ] **3.1.3** Slide 2 : Inventaire
  - Titre : "Suivez votre inventaire"
  - Illustration inventaire (`Icon(Icons.inventory)`)
  - Texte : "Ne perdez plus rien, sachez toujours ce que vous avez"

- [ ] **3.1.4** Slide 3 : Budget
  - Titre : "Maîtrisez votre budget"
  - Illustration budget (`Icon(Icons.account_balance_wallet)`)
  - Texte : "Contrôlez vos dépenses mensuelles facilement"

- [ ] **3.1.5** Slide 4 : Alertes (optionnel)
  - Titre : "Recevez des alertes intelligentes"
  - Illustration notification (`Icon(Icons.notifications_active)`)
  - Texte : "Soyez prévenu des dates d'expiration et ruptures de stock"

- [ ] **3.1.6** Ajouter bouton "Passer"
  - Positionner en haut à droite de chaque slide
  - Utiliser `TextButton("Passer", onPressed: _skipOnboarding)`
  - Méthode `_skipOnboarding()` :
    - Sauvegarder `SharedPreferences: onboarding_completed = true`
    - Naviguer vers `DashboardScreen` avec `Navigator.pushReplacement()`

- [ ] **3.1.7** Intégrer dans flux initial
  - Dans `main.dart`, après chargement app :
    - Lire `SharedPreferences.getBool('onboarding_completed')`
    - Si `false` ou null → afficher `OnboardingScreen`
    - Si `true` → afficher `DashboardScreen`

#### Tests pour Task 3.1

- [ ] **Test 3.1.T1** : Widget test OnboardingScreen affiche 3-4 slides
  - Créer test widget
  - Vérifier présence de `PageView`
  - Swiper et vérifier contenu de chaque slide

- [ ] **Test 3.1.T2** : Widget test bouton "Passer" fonctionne
  - Tap sur "Passer"
  - Vérifier navigation vers dashboard

- [ ] **Test 3.1.T3** : Integration test - compléter onboarding → dashboard
  - Swiper jusqu'au dernier slide
  - Tap "Terminer"
  - Vérifier SharedPreferences updated
  - Vérifier navigation dashboard

- [ ] **F2P Check** : Premier lancement affiche onboarding, relancement non

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 3.2: Messages d'Erreur User-Friendly

**Liée à** : Requirement V1.8 (User-Friendly Error Messages)

- [ ] **3.2.1** Créer `ErrorMessageService`
  - Créer `lib/services/error_message_service.dart`
  - Map d'erreurs techniques → messages FR :
    ```dart
    static const _errorMessages = {
      'SocketException': 'Vérifiez votre connexion Internet',
      'TimeoutException': 'La requête a pris trop de temps',
      'FormatException': 'Données invalides, veuillez réessayer',
      'DatabaseException': 'Erreur de base de données',
    };
    ```
  - Méthode `String getUserMessage(dynamic error)` :
    - Extraire type d'erreur
    - Retourner message user-friendly ou message générique

- [ ] **3.2.2** Intégrer dans tous les `try/catch`
  - Auditer codebase : `grep -r "catch (e)" lib/`
  - Pour chaque catch :
    - Logger avec `ErrorLoggerService.log(e, stackTrace)`
    - Afficher message user avec `ErrorMessageService.getUserMessage(e)`
    - Utiliser `SnackBar` ou `showDialog` pour UI

- [ ] **3.2.3** Ajouter illustrations d'erreur
  - Créer assets : `assets/images/no_internet.svg`, `error_generic.svg`
  - Dans dialog d'erreur, afficher `SvgPicture.asset('assets/images/...')`
  - Tester visuellement

- [ ] **3.2.4** Tester avec utilisateurs non techniques
  - Provoquer erreurs courantes :
    - Désactiver WiFi → erreur "pas d'internet"
    - Entrer données invalides → erreur "format invalide"
  - Demander à utilisateur non tech de lire message
  - Itérer si confusion

#### Tests pour Task 3.2

- [ ] **Test 3.2.T1** : Unit test `ErrorMessageService.getUserMessage()` retourne bon texte
  - Tester avec `SocketException` → attend "Vérifiez votre connexion Internet"
  - Tester avec erreur inconnue → attend message générique

- [ ] **Test 3.2.T2** : Widget test dialog erreur affiche illustration + message
  - Afficher dialog avec erreur test
  - Vérifier présence de `SvgPicture`
  - Vérifier texte message

- [ ] **F2P Check** : Messages d'erreur compréhensibles par personne non technique

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 3.3: Quick Actions Dashboard

**Liée à** : Requirement V1.9 (Functional Quick Actions)

- [ ] **3.3.1** Identifier quick actions nécessaires
  - "Ajouter un produit" → route `/add-product`
  - "Voir inventaire" → route `/inventory`
  - "Budget" → route `/budget`
  - "Paramètres" → route `/settings`

- [ ] **3.3.2** Créer widget `QuickActionButton`
  - Créer `lib/widgets/quick_action_button.dart`
  - Widget réutilisable avec params : `IconData icon`, `String label`, `VoidCallback onTap`
  - Contraintes : taille minimum 44x44 (iOS) ou 48x48 (Android)
  - Semantic label pour accessibilité

- [ ] **3.3.3** Implémenter navigation pour chaque action
  - Dans `DashboardScreen`, créer 4 `QuickActionButton`
  - OnTap : `Navigator.pushNamed(context, '/route')`
  - Vérifier routes définies dans `main.dart`
  - Tester navigation sur iOS et Android
  - Gérer retour arrière (pop) correct

- [ ] **3.3.4** Designer icônes et labels
  - Icônes Material cohérentes :
    - Add Product : `Icons.add_shopping_cart`
    - Inventory : `Icons.inventory_2`
    - Budget : `Icons.account_balance_wallet`
    - Settings : `Icons.settings`
  - Labels FR via l10n : `AppLocalizations.of(context).addProduct`, etc.
  - Espacement : `Row` ou `GridView` avec `mainAxisSpacing: 16`

#### Tests pour Task 3.3

- [ ] **Test 3.3.T1** : Widget test `QuickActionButton` affiche icône + label
  - Render widget avec params test
  - Vérifier présence `Icon` et `Text`

- [ ] **Test 3.3.T2** : Integration test - tap sur chaque action navigue correctement
  - Tap "Add Product" → vérifier route `/add-product`
  - Tap "Inventory" → vérifier route `/inventory`
  - Tap "Budget" → vérifier route `/budget`
  - Tap "Settings" → vérifier route `/settings`

- [ ] **Test 3.3.T3** : Test accessibilité - semantic labels présents
  - Vérifier `Semantics` widget wrapping buttons
  - Vérifier labels clairs pour screen readers

- [ ] **F2P Check** : Toutes les actions mènent aux bons écrans (test manuel iOS/Android)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 4: Performance & Store (Semaines 8-9)

### Task 4.1: Optimisation Performance

**Liée à** : Requirement V1.10 (Performance Optimization)

- [ ] **4.1.1** Créer dataset de test (500+ produits)
  - Script Dart pour générer 500 produits fictifs
  - Fichier `scripts/generate_test_data.dart`
  - Insérer via `DatabaseService` ou SQL direct
  - Vérifier taille DB reste < 10MB

- [ ] **4.1.2** Profiler dashboard avec 500+ produits
  - Ouvrir DevTools → Performance tab
  - Enregistrer trace lors du chargement dashboard
  - Identifier widgets lents (rebuild excessifs, layouts complexes)
  - Documenter findings

- [ ] **4.1.3** Implémenter pagination/lazy loading
  - Remplacer `ListView` par `ListView.builder` (si pas déjà fait)
  - Charger produits par batch de 50
  - Détecter scroll fin de liste : `ScrollController`
  - Charger prochaine page quand proche du bas

- [ ] **4.1.4** Optimiser requêtes SQLite
  - Vérifier indexes sur colonnes filtrées (`household_id`, `category`, etc.)
  - Utiliser `LIMIT` et `OFFSET` pour pagination SQL
  - Mesurer temps requête avec `Stopwatch` :
    ```dart
    final sw = Stopwatch()..start();
    final products = await db.query(...);
    print('Query time: ${sw.elapsedMilliseconds}ms');
    ```
  - Optimiser si > 100ms

- [ ] **4.1.5** Tester sur appareil bas de gamme
  - Emprunter/acheter appareil Android 8.0, 2GB RAM
  - Installer APK release
  - Tester fluidité scroll, chargement dashboard
  - Documenter lags identifiés et corriger

#### Tests pour Task 4.1

- [ ] **Test 4.1.T1** : Performance test - dashboard charge en <2s avec 500 produits
  - Créer integration test avec 500 produits
  - Mesurer temps de chargement dashboard
  - Assert < 2000ms

- [ ] **Test 4.1.T2** : Performance test - scroll fluide (60fps)
  - Mesurer frame times pendant scroll
  - Vérifier aucun jank (frame > 16ms)

- [ ] **Test 4.1.T3** : Memory test - pas de leak après 10 minutes
  - Utiliser DevTools → Memory
  - Observer heap growth sur 10 minutes d'utilisation
  - Vérifier stabilité (pas de croissance linéaire)

- [ ] **F2P Check** : App fluide sur Android 8.0 / 2GB RAM (test manuel)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 4.2: Store Compliance

**Liée à** : Requirement V1.11 (Store Compliance)

- [ ] **4.2.1** Checklist Apple App Store
  - Privacy Policy URL présente dans app
  - Toutes permissions justifiées (camera, photos, etc.)
  - Pas de crash sur flux principaux
  - Respect guidelines : pas de contenu inapproprié, pas de liens externes trompeurs
  - Documenter checklist dans `docs/store_compliance_ios.md`

- [ ] **4.2.2** Checklist Google Play Store
  - Privacy Policy URL présente
  - Target SDK ≥ API 33 (Android 13)
  - Permissions déclarées dans `AndroidManifest.xml`
  - Pas de boutons non fonctionnels
  - Icône app launcher conforme (512x512 PNG)
  - Documenter checklist dans `docs/store_compliance_android.md`

- [ ] **4.2.3** Créer Privacy Policy
  - Rédiger policy sur Google Docs ou Notion
  - Sections : données collectées, usage, partage, droits utilisateur
  - Héberger sur site web (GitHub Pages, Netlify, ou domaine)
  - Ajouter lien dans Settings screen de l'app

- [ ] **4.2.4** Audit final - pas de features fake
  - Ouvrir app et cliquer sur TOUS les boutons visibles
  - Vérifier qu'aucun n'affiche "Coming soon" sans contexte clair
  - Vérifier qu'aucun ne fait rien (dead button)
  - Corriger ou masquer avec feature flags

#### Tests pour Task 4.2

- [ ] **Test 4.2.T1** : Audit manuel - tous les boutons fonctionnent
  - Checklist manuelle de navigation
  - Documenter résultats

- [ ] **Test 4.2.T2** : Build release Android - no crash sur flux principaux
  - Build APK release
  - Tester : onboarding → add product → view inventory → budget → settings
  - Vérifier aucun crash

- [ ] **Test 4.2.T3** : Build release iOS - no crash sur flux principaux
  - Build IPA release
  - Tester flux principaux
  - Vérifier aucun crash

- [ ] **F2P Check** : Aucune promesse mensongère dans l'UI (test manuel)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 5: Tests & Validation (Semaines 10-11)

### Task 5.1: Tests Automatisés

**Liée à** : Requirement TEST.1 (Automated Testing Coverage)

- [ ] **5.1.1** Tests unitaires `FeatureFlagService`
  - Créer `test/services/feature_flag_service_test.dart`
  - Test `isCloudSyncEnabled()` en dev et prod
  - Test `isPremiumEnabled()` retourne false
  - Atteindre couverture ≥ 80%

- [ ] **5.1.2** Tests unitaires `DatabaseService`
  - Créer `test/services/database_service_test.dart`
  - Test migrations 0001 à 0012 sur base vide
  - Test upgrade de v11 à v12
  - Test CRUD sur chaque table importante
  - Test erreurs (DB locked, contraintes violées)
  - Atteindre couverture ≥ 80%

- [ ] **5.1.3** Tests unitaires `BudgetService`
  - Créer `test/services/budget_service_test.dart`
  - Test calculs : spent, remaining, percentage
  - Test alertes à 90% et 100%
  - Test edge cases (budget = 0, négatif)
  - Atteindre couverture ≥ 80%

- [ ] **5.1.4** Tests unitaires `AlertService`
  - Créer `test/services/alert_service_test.dart`
  - Test génération alertes péremption
  - Test fusion avec `AlertStateRepository`
  - Test logique "lu" / "résolu"
  - Atteindre couverture ≥ 80%

- [ ] **5.1.5** Tests d'intégration flux principal
  - Créer `integration_test/main_flow_test.dart`
  - Flux : Onboarding → Add Product → View Inventory → Budget
  - Vérifier données persistées entre étapes
  - Vérifier navigation correcte

- [ ] **5.1.6** Tests widgets critiques
  - `test/screens/dashboard_screen_test.dart`
  - `test/screens/add_product_screen_test.dart`
  - `test/screens/budget_screen_test.dart`
  - `test/screens/settings_screen_test.dart`
  - Vérifier rendering, interactions basiques

#### Tests pour Task 5.1

- [ ] **Test 5.1.T1** : Coverage globale ≥ 70%
  - Exécuter `flutter test --coverage`
  - Générer rapport HTML avec `genhtml`
  - Vérifier couverture globale

- [ ] **Test 5.1.T2** : Tous les tests passent en CI (si configuré)
  - Configurer GitHub Actions ou similaire
  - Vérifier tous tests passent automatiquement

- [ ] **F2P Check** : Tests réellement validés (pas de faux positifs)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 6: Publication (Semaines 12-13)

### Task 6.1: Préparation Stores

**Liée à** : Requirements V1.11, 22.* (Store Submission)

- [ ] **6.1.1** Screenshots App Store/Play Store
  - Créer 5+ screenshots par plateforme :
    - iPhone (6.5", 5.5")
    - iPad (12.9")
    - Android phone (1080x1920)
    - Android tablet (optional)
  - Utiliser outil : Figma, Canva, ou captures réelles + annotations
  - Localiser en FR (et EN si possible)
  - Sauvegarder dans `assets/store/screenshots/`

- [ ] **6.1.2** Vidéo démo 30-60s
  - Planifier scénario : ouverture app → onboarding → add product → budget alert
  - Enregistrer écran avec OBS ou QuickTime
  - Ajouter sous-titres FR avec DaVinci Resolve ou similaire
  - Exporter formats requis (MP4 pour iOS, MP4/WEBM pour Android)
  - Durée 30-60s max

- [ ] **6.1.3** Description optimisée SEO
  - Rechercher mots-clés : inventaire, budget, Cameroun, maison, gestion domestique
  - Rédiger description FR (max 4000 chars) :
    - Titre accrocheur
    - 3-5 points clés
    - Call to action
  - Traduire en EN
  - Sauvegarder dans `assets/store/descriptions/`

- [ ] **6.1.4** Soumettre à App Store
  - Créer app dans App Store Connect
  - Uploader build release via Xcode ou Transporter
  - Remplir metadata : nom, description, screenshots, vidéo
  - Configurer prix (gratuit), catégorie (Productivity ou Lifestyle)
  - Soumettre pour review

- [ ] **6.1.5** Soumettre à Play Store
  - Créer app dans Play Console
  - Générer AAB release : `flutter build appbundle --release --obfuscate`
  - Uploader AAB via console
  - Remplir metadata : titre court, description complète, screenshots
  - Configurer release track (Internal → Closed → Open Beta → Production)
  - Soumettre pour review

#### Tests pour Task 6.1

- [ ] **Test 6.1.T1** : Build release iOS réussit et fonctionne
  - `flutter build ios --release --obfuscate`
  - Installer sur device iOS test
  - Tester flux principaux

- [ ] **Test 6.1.T2** : Build release Android réussit et fonctionne
  - `flutter build apk --release --obfuscate`
  - Installer sur device Android test
  - Tester flux principaux

- [ ] **F2P Check** : App installable et fonctionnelle sur vrai device (test manuel)

- [ ] **P2F Check** : `flutter test` passe à 100%

---

**FIN DES TASKS V1**

---

## Notes pour l'IA (Cline/Cursor/Windsurf)

- Travailler UNIQUEMENT sur les tâches V1 sauf instruction contraire.
- Chaque tâche doit passer F2P + P2F avant d'être marquée DONE.
- Respecter AI_RULES.md : code efficient, idiomatique Dart, pas de nouveaux fichiers si existant utilisable.
- Avant de créer un service/repository, vérifier si `lib/services/X_service.dart` ou `lib/repository/X_repository.dart` existe déjà.
- Toujours écrire les tests listés dans section "Tests" AVANT de marquer tâche terminée.
- Si une tâche semble trop grosse, proposer découpage en sous-tâches plus petites.
- NE PAS modifier le scope fonctionnel sans accord explicite de l'utilisateur.
