# NGONNEST – TASKS V1 (MVP OFFLINE-ONLY)

> Ce fichier contient UNIQUEMENT les tâches V1 MVP.
> Pour V2/V3, voir `tasks_v2.md` et `tasks_v3_future.md`.
> Toutes les tâches respectent AI_RULES.md et requirements.md (V1.*).

## 0. Règles de Validation des Tâches

Une tâche est **DONE** uniquement si :

### F2P (False-to-Positive Check)
- Le code fait RÉELLEMENT ce qui est décrit (pas de faux positif).
- Vérification manuelle fonctionnelle

### P2F (Pass-to-Fail Check)
- `flutter test` passe à 100% (unit + widget + integration concernés).
- Aucun test cassé par la modification.

---

## Phase 1: Fondations Critiques (Semaines 1-3)

### Task 1.1: Sécurité & Configuration Environnement

**Liée à** : Requirement V1.1 (Security and Configuration Management)

- [ ] **1.1.1** Installer et configurer `flutter_dotenv`
  - Ajouter `flutter_dotenv: ^5.1.0` dans `pubspec.yaml`
  - Créer `.env.example` avec clés vides (`SUPABASE_URL=`, `SUPABASE_ANON_KEY=`)
  - Ajouter `.env` dans `.gitignore`
  - Créer `.env.dev` et `.env.prod` (non commités)
  - Tester le chargement avec `dotenv.load()` dans `main.dart`

- [ ] **1.1.2** Créer service de configuration sécurisé
  - Créer `lib/config/env_config.dart`
  - Implémenter `EnvConfig.supabaseUrl` via `dotenv.env['SUPABASE_URL']`
  - Implémenter `EnvConfig.supabaseAnonKey`
  - Ajouter validation : lever exception si clé manquante
  - Documenter avec `///` docstrings

- [ ] **1.1.3** Migrer toutes les références hardcodées
  - Chercher tous les `String.*supabase` dans le code
  - Remplacer par `EnvConfig.supabaseUrl` / `.supabaseAnonKey`
  - Vérifier qu'aucune clé ne reste en clair
  - Compiler et valider que l'app démarre

- [ ] **1.1.4** Configurer obfuscation pour release builds
  - Ajouter `--obfuscate --split-debug-info=build/app/outputs/symbols` dans scripts de build
  - Tester un build release : `flutter build apk --release --obfuscate`
  - Vérifier que les symbols sont dans `build/app/outputs/symbols`
  - Documenter dans `README.md`

#### Tests pour Task 1.1
- [ ] **Test 1.1.T1** : Unit test `EnvConfig` lance exception si `.env` manque
- [ ] **Test 1.1.T2** : Build release réussit sans erreur
- [ ] **Test 1.1.T3** : Décompiler l'APK release et vérifier absence de clés en clair (manuel)
- [ ] **F2P Check** : L'app fonctionne avec `.env.dev` et `.env.prod` distincts
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 1.2: Feature Flags Service

**Liée à** : Requirement V1.2 (Feature Flags System)

- [ ] **1.2.1** Créer `FeatureFlagService` de base
  - Créer `lib/services/feature_flag_service.dart`
  - Implémenter méthode `bool isCloudSyncEnabled()`
  - Implémenter méthode `bool isPremiumEnabled()`
  - Retourner `false` en dur pour V1 (documenter avec `// V1: disabled`)

- [ ] **1.2.2** Détecter environnement (dev vs prod)
  - Ajouter `bool get isDevMode => kDebugMode || kProfileMode`
  - En dev : `isCloudSyncEnabled` retourne `true` (pour tests futurs)
  - En release : `isCloudSyncEnabled` retourne `false`
  - Tester avec `flutter run --release`

- [ ] **1.2.3** Intégrer dans Provider
  - Ajouter `Provider<FeatureFlagService>` dans `main.dart`
  - Rendre accessible via `context.read<FeatureFlagService>()`
  - Tester l'injection dans `SettingsScreen`

- [ ] **1.2.4** Modifier UI Settings pour désactiver sync
  - Dans `settings_screen.dart`, récupérer `FeatureFlagService`
  - Si `!isCloudSyncEnabled`, griser le bouton sync
  - Ajouter tooltip "Fonctionnalité bientôt disponible"
  - Empêcher tout appel à `SyncService` si flag = false

#### Tests pour Task 1.2
- [ ] **Test 1.2.T1** : Unit test `FeatureFlagService.isCloudSyncEnabled()` retourne false en release
- [ ] **Test 1.2.T2** : Widget test `SettingsScreen` affiche bouton grisé en release
- [ ] **Test 1.2.T3** : Integration test : tap sur sync désactivé ne déclenche rien
- [ ] **F2P Check** : En mode release, impossible d'activer le sync manuellement
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 1.3: Persistence des États d'Alertes

**Liée à** : Requirement V1.3 (Alert Persistence System)

- [ ] **1.3.1** Concevoir schéma SQL `alert_states`
  - Créer fichier `migrations/0012_alert_states.sql` (documenter)
  - Colonnes : `id INTEGER PRIMARY KEY`, `alert_id TEXT`, `is_read INTEGER`, `is_resolved INTEGER`, `updated_at TEXT`
  - Index sur `alert_id` pour performance
  - Ajouter contrainte `UNIQUE(alert_id)`

- [ ] **1.3.2** Implémenter migration dans `DatabaseService`
  - Ajouter migration `0012_alert_states` dans `_migrations` list
  - Implémenter `_createAlertStatesTable(Database db)`
  - Tester migration sur base vide (nouvelle install)
  - Tester migration sur base existante (upgrade depuis v11)

- [ ] **1.3.3** Créer modèle `AlertState`
  - Créer `lib/models/alert_state.dart`
  - Champs : `String alertId`, `bool isRead`, `bool isResolved`, `DateTime updatedAt`
  - Méthodes `toMap()` et `fromMap(Map<String, dynamic> map)`
  - Méthode `copyWith()` pour modifications immutables

- [ ] **1.3.4** Implémenter Repository `AlertStateRepository`
  - Créer `lib/repository/alert_state_repository.dart`
  - Méthode `Future<void> saveAlertState(AlertState state)`
  - Méthode `Future<AlertState?> getAlertState(String alertId)`
  - Méthode `Future<Map<String, AlertState>> getAllAlertStates()`
  - Utiliser `INSERT OR REPLACE` pour upsert

- [ ] **1.3.5** Intégrer dans `AlertService`
  - Ajouter méthode `markAlertAsRead(String alertId)`
  - Ajouter méthode `markAlertAsResolved(String alertId)`
  - Au chargement des alertes, fusionner avec `AlertStateRepository.getAllAlertStates()`
  - Implémenter logique : alerte lue → ne plus notifier

- [ ] **1.3.6** UI feedback pour changements d'état
  - Dans la liste des alertes, afficher icône "œil barré" si `isRead`
  - Afficher icône "checkmark" si `isResolved`
  - Ajouter animation de fade-out quand alerte résolue
  - Tester avec 10, 50, 100+ alertes

#### Tests pour Task 1.3
- [ ] **Test 1.3.T1** : Unit test migration `0012_alert_states` sur base vide
- [ ] **Test 1.3.T2** : Unit test migration sur upgrade depuis v11
- [ ] **Test 1.3.T3** : Unit test `AlertStateRepository.saveAlertState()` fonctionne
- [ ] **Test 1.3.T4** : Unit test `AlertStateRepository.getAlertState()` retourne bon état
- [ ] **Test 1.3.T5** : Integration test : marquer alerte lue, redémarrer app, vérifier état persisté
- [ ] **Test 1.3.T6** : Performance test : 1000 alertes chargées en <2s
- [ ] **F2P Check** : Une alerte marquée lue ne réapparaît jamais comme "non lue"
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 1.4: Inventaire CRUD Complet Offline

**Liée à** : Requirement V1.4 (Offline Inventory Management)

- [ ] **1.4.1** Audit CRUD existant
  - Vérifier `InventoryRepository.addProduct()` persiste bien en SQLite
  - Vérifier `InventoryRepository.updateProduct()` fonctionne
  - Vérifier `InventoryRepository.deleteProduct()` supprime correctement
  - Identifier tout code "fake" (données en mémoire uniquement)

- [ ] **1.4.2** Corriger `addProduct` si nécessaire
  - S'assurer que `addProduct` retourne l'ID du produit créé
  - Ajouter validation : nom non vide, quantité > 0
  - Gérer les erreurs SQLite (contraintes, etc.)
  - Ajouter log via `ErrorLoggerService` en cas d'erreur

- [ ] **1.4.3** Corriger `updateProduct` si nécessaire
  - Implémenter `UPDATE` avec `WHERE id = ?`
  - Valider que l'ID existe avant update
  - Retourner succès/échec via `Future<bool>`
  - Tester modification de chaque champ individuellement

- [ ] **1.4.4** Corriger `deleteProduct` si nécessaire
  - Implémenter `DELETE FROM products WHERE id = ?`
  - Vérifier que les dépendances (budgets, alertes) sont gérées
  - Implémenter soft-delete ou hard-delete (décision à documenter)
  - Ajouter confirmation UI avant suppression

- [ ] **1.4.5** Implémenter recherche SQLite
  - Créer `Future<List<Product>> searchProducts(String query)`
  - Utiliser `WHERE name LIKE ?` (paramétrisé pour sécurité)
  - Limiter résultats à 100 par défaut
  - Tester performance avec 500+ produits

- [ ] **1.4.6** Tester persistance après redémarrage
  - Ajouter un produit
  - Fermer l'app complètement (kill process)
  - Redémarrer l'app
  - Vérifier que le produit est toujours là

#### Tests pour Task 1.4
- [ ] **Test 1.4.T1** : Unit test `addProduct()` insère bien en DB
- [ ] **Test 1.4.T2** : Unit test `updateProduct()` modifie le bon produit
- [ ] **Test 1.4.T3** : Unit test `deleteProduct()` supprime correctement
- [ ] **Test 1.4.T4** : Unit test `searchProducts()` retourne résultats pertinents
- [ ] **Test 1.4.T5** : Integration test : CRUD complet sur 1 produit
- [ ] **Test 1.4.T6** : Integration test : recherche sur 500 produits en <1s
- [ ] **F2P Check** : Données persistent après redémarrage app (test manuel)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 2: Budget & Prix (Semaines 4-5)

### Task 2.1: Budget Basique Offline

**Liée à** : Requirement V1.5 (Basic Budget Management)

- [ ] **2.1.1** Créer/valider table budget SQLite
  - Vérifier table `budgets` existe avec colonnes : `id`, `household_id`, `monthly_limit`, `month`, `year`
  - Créer migration si manquante
  - Ajouter index sur `(household_id, month, year)`

- [ ] **2.1.2** Implémenter `BudgetRepository.setBudget()`
  - Méthode `Future<void> setBudget(int householdId, double monthlyLimit, int month, int year)`
  - Utiliser `INSERT OR REPLACE`
  - Valider `monthlyLimit > 0`

- [ ] **2.1.3** Implémenter calcul des dépenses
  - Méthode `Future<double> getTotalSpent(int householdId, int month, int year)`
  - Joindre avec table `products` ou `purchases` (selon modèle)
  - Somme des prix des produits ajoutés ce mois
  - Optimiser la requête (éviter full scan)

- [ ] **2.1.4** Implémenter vue budget simple
  - Dans `BudgetScreen`, afficher : Budget total, Dépensé, Reste
  - Calculer % consommé : `(spent / budget) * 100`
  - Afficher barre de progression visuelle
  - Couleur : vert si <70%, orange si 70-90%, rouge si >90%

- [ ] **2.1.5** Implémenter alertes budget
  - Si % > 90%, déclencher alerte "Attention, 90% du budget atteint"
  - Si % > 100%, alerte "Budget dépassé !"
  - Persister état des alertes dans `alert_states`
  - Afficher alerte en haut du dashboard

#### Tests pour Task 2.1
- [ ] **Test 2.1.T1** : Unit test `setBudget()` enregistre bien le budget
- [ ] **Test 2.1.T2** : Unit test `getTotalSpent()` calcule correctement
- [ ] **Test 2.1.T3** : Widget test `BudgetScreen` affiche les bonnes valeurs
- [ ] **Test 2.1.T4** : Integration test : dépasser 90% déclenche alerte
- [ ] **Test 2.1.T5** : Integration test : dépasser 100% déclenche alerte
- [ ] **F2P Check** : Budget et dépenses corrects après ajout de 10 produits
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 2.2: Prix Locaux & RegionConfig

**Liée à** : Requirement V1.6 (Price Database)

- [ ] **2.2.1** Créer classe `RegionConfig`
  - Créer `lib/config/region_config.dart`
  - Champs : `String countryCode`, `String currencyCode`, `String currencySymbol`
  - Méthode statique `RegionConfig.detect()` → détecte pays via `Intl.systemLocale`
  - Fallback sur Cameroun (`CM`, `XAF`, `FCFA`) si détection échoue

- [ ] **2.2.2** Implémenter support multi-devises
  - Map : `{'CM': RegionConfig('CM', 'XAF', 'FCFA'), 'NG': RegionConfig('NG', 'NGN', '₦'), ...}`
  - Méthode `formatPrice(double amount, RegionConfig region)` → formatage correct
  - Tester avec Cameroun et Nigeria

- [ ] **2.2.3** Charger base de prix Cameroun
  - Créer fichier `assets/data/cameroon_prices.json`
  - Format : `[{"category": "Légumes", "product": "Tomate", "price": 500, "unit": "kg", "source": "Mahima Douala", "updated": "2025-12-01"}, ...]`
  - Charger au démarrage via `rootBundle.loadString()`
  - Parser et stocker dans SQLite (`prices` table)

- [ ] **2.2.4** Créer service `PriceService`
  - Méthode `Future<double?> getAveragePrice(String category, String product)`
  - Méthode `Future<void> updatePrice(String product, double price, String source)`
  - Exposer via Provider

- [ ] **2.2.5** Intégrer prix dans formulaire ajout produit
  - Suggérer prix moyen quand catégorie/produit sélectionnés
  - Permettre modification manuelle
  - Enregistrer prix saisi si différent du prix moyen

#### Tests pour Task 2.2
- [ ] **Test 2.2.T1** : Unit test `RegionConfig.detect()` retourne bon pays
- [ ] **Test 2.2.T2** : Unit test `formatPrice()` formate correctement XAF et NGN
- [ ] **Test 2.2.T3** : Unit test chargement `cameroon_prices.json` réussit
- [ ] **Test 2.2.T4** : Unit test `PriceService.getAveragePrice()` retourne prix correct
- [ ] **Test 2.2.T5** : Widget test formulaire suggère bon prix
- [ ] **F2P Check** : Prix affichés sont réalistes pour Cameroun (vérif manuelle)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 3: UX & Navigation (Semaines 6-7)

### Task 3.1: Onboarding Simple

**Liée à** : Requirement V1.7 (Simple Onboarding Flow)

- [ ] **3.1.1** Créer écran OnboardingScreen
  - Créer `lib/screens/onboarding_screen.dart`
  - Utiliser `PageView` pour slides
  - 3-4 slides : Bienvenue, Inventaire, Budget, Alertes

- [ ] **3.1.2** Slide 1 : Bienvenue
  - Titre : "Bienvenue sur NgonNest"
  - Illustration (asset ou icon)
  - Texte : "Gérez votre maison intelligemment"
  - Bouton "Suivant"

- [ ] **3.1.3** Slide 2 : Inventaire
  - Titre : "Suivez votre inventaire"
  - Illustration inventaire
  - Texte : "Ne perdez plus rien, sachez ce que vous avez"

- [ ] **3.1.4** Slide 3 : Budget
  - Titre : "Maîtrisez votre budget"
  - Illustration budget
  - Texte : "Contrôlez vos dépenses mensuelles facilement"

- [ ] **3.1.5** Slide 4 : Alertes (optionnel, peut être fusionné)
  - Titre : "Recevez des alertes"
  - Illustration notification
  - Texte : "Soyez prévenu des dates d'expiration"

- [ ] **3.1.6** Ajouter bouton "Passer"
  - En haut à droite de chaque slide
  - Navigue directement vers dashboard
  - Enregistre `onboarding_completed = true` dans SharedPreferences

- [ ] **3.1.7** Intégrer dans flux initial
  - Dans `main.dart`, vérifier `onboarding_completed`
  - Si `false`, afficher `OnboardingScreen`
  - Si `true`, afficher `DashboardScreen`

#### Tests pour Task 3.1
- [ ] **Test 3.1.T1** : Widget test OnboardingScreen affiche 3-4 slides
- [ ] **Test 3.1.T2** : Widget test bouton "Passer" fonctionne
- [ ] **Test 3.1.T3** : Integration test : compléter onboarding → dashboard
- [ ] **F2P Check** : Premier lancement affiche onboarding, relancement non
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 3.2: Messages d'Erreur User-Friendly

**Liée à** : Requirement V1.8 (User-Friendly Error Messages)

- [ ] **3.2.1** Créer `ErrorMessageService`
  - Créer `lib/services/error_message_service.dart`
  - Map d'erreurs techniques → messages FR clairs
  - Exemple : `"SocketException" → "Vérifiez votre connexion Internet"`

- [ ] **3.2.2** Intégrer dans tous les `try/catch`
  - Auditer code pour identifier tous les `catch (e)`
  - Remplacer `print(e)` par `ErrorLoggerService.log(e)` + `ErrorMessageService.getUserMessage(e)`
  - Afficher message user-friendly en SnackBar/Dialog

- [ ] **3.2.3** Ajouter illustrations d'erreur
  - Créer assets : `no_internet.svg`, `error_generic.svg`
  - Afficher illustration dans dialog d'erreur
  - Tester visuellement

- [ ] **3.2.4** Tester avec utilisateurs non techniques
  - Provoquer erreurs courantes (pas d'internet, DB locked, etc.)
  - Demander à utilisateur non tech de comprendre le message
  - Itérer si confusion

#### Tests pour Task 3.2
- [ ] **Test 3.2.T1** : Unit test `ErrorMessageService.getUserMessage()` retourne bon texte
- [ ] **Test 3.2.T2** : Widget test dialog erreur affiche illustration + message
- [ ] **F2P Check** : Messages d'erreur compréhensibles par mère camerounaise de 52 ans
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 3.3: Quick Actions Dashboard

**Liée à** : Requirement V1.9 (Functional Quick Actions)

- [ ] **3.3.1** Identifier quick actions nécessaires
  - "Ajouter un produit" → `AddProductScreen`
  - "Voir inventaire" → `InventoryScreen`
  - "Budget" → `BudgetScreen`
  - "Paramètres" → `SettingsScreen`

- [ ] **3.3.2** Créer widget `QuickActionButton`
  - Widget réutilisable : icône + label + onTap
  - Taille tactile minimum 44x44
  - Accessible (semantic label)

- [ ] **3.3.3** Implémenter navigation pour chaque action
  - Vérifier routes existantes dans `main.dart`
  - Tester navigation sur iOS et Android
  - Gérer retour arrière correct

- [ ] **3.3.4** Designer icônes et labels
  - Icônes Material ou Cupertino cohérentes
  - Labels FR localisés via i18n
  - Espacement visuel agréable

#### Tests pour Task 3.3
- [ ] **Test 3.3.T1** : Widget test `QuickActionButton` affiche icône + label
- [ ] **Test 3.3.T2** : Integration test : tap sur chaque action navigue correctement
- [ ] **Test 3.3.T3** : Test accessibilité : semantic labels présents
- [ ] **F2P Check** : Toutes les actions mènent aux bons écrans (test manuel iOS/Android)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 4: Performance & Store (Semaines 8-9)

### Task 4.1: Optimisation Performance

**Liée à** : Requirement V1.10 (Performance Optimization)

- [ ] **4.1.1** Créer dataset de test (500+ produits)
  - Script pour générer 500 produits fictifs
  - Insérer dans SQLite
  - Vérifier taille DB reste raisonnable (<10MB)

- [ ] **4.1.2** Profiler dashboard avec 500+ produits
  - Ouvrir DevTools → Performance
  - Mesurer temps de chargement dashboard
  - Identifier widgets lents (rebuild excessifs)

- [ ] **4.1.3** Implémenter pagination/lazy loading
  - ListView.builder au lieu de ListView (si pas déjà fait)
  - Charger 50 produits à la fois
  - Implémenter scroll infini

- [ ] **4.1.4** Optimiser requêtes SQLite
  - Vérifier indexes sur colonnes filtrées
  - Utiliser `LIMIT` et `OFFSET` pour pagination
  - Mesurer temps de requête avec `Stopwatch`

- [ ] **4.1.5** Tester sur appareil bas de gamme
  - Emprunter/acheter appareil Android 8.0, 2GB RAM
  - Installer app et tester fluidité
  - Corriger lags identifiés

#### Tests pour Task 4.1
- [ ] **Test 4.1.T1** : Performance test : dashboard charge en <2s avec 500 produits
- [ ] **Test 4.1.T2** : Performance test : scroll fluide (60fps)
- [ ] **Test 4.1.T3** : Memory test : pas de leak après 10 minutes d'utilisation
- [ ] **F2P Check** : App fluide sur Android 8.0 / 2GB RAM (test manuel)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

### Task 4.2: Store Compliance

**Liée à** : Requirement V1.11 (Store Compliance)

- [ ] **4.2.1** Checklist Apple App Store
  - Privacy Policy URL présente
  - Toutes les permissions justifiées
  - Pas de crash sur flux principaux
  - Respect guidelines (pas de contenu inapproprié, etc.)

- [ ] **4.2.2** Checklist Google Play Store
  - Privacy Policy URL présente
  - Target SDK ≥ Android 13
  - Permissions déclarées dans manifest
  - Pas de boutons non fonctionnels

- [ ] **4.2.3** Créer Privacy Policy
  - Rédiger policy : données collectées, usage, partage
  - Héberger sur site web (ou GitHub Pages)
  - Ajouter lien dans app settings

- [ ] **4.2.4** Audit final : pas de features fake
  - Cliquer sur tous les boutons de l'app
  - Vérifier qu'aucun ne fait rien ou affiche "Coming soon" sans contexte
  - Corriger ou masquer

#### Tests pour Task 4.2
- [ ] **Test 4.2.T1** : Audit manuel : tous les boutons fonctionnent
- [ ] **Test 4.2.T2** : Build release Android : no crash sur flux principaux
- [ ] **Test 4.2.T3** : Build release iOS : no crash sur flux principaux
- [ ] **F2P Check** : Aucune promesse mensongère dans l'UI (test manuel)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 5: Tests & Validation (Semaines 10-11)

### Task 5.1: Tests Automatisés

**Liée à** : Requirement TEST.1 (Automated Testing Coverage)

- [ ] **5.1.1** Tests unitaires `FeatureFlagService`
  - Test `isCloudSyncEnabled()` en dev et prod
  - Test `isPremiumEnabled()` retourne false
  - Couverture ≥ 80%

- [ ] **5.1.2** Tests unitaires `DatabaseService`
  - Test migrations (0001 à 0012)
  - Test CRUD sur chaque table
  - Test erreurs (DB locked, contraintes)
  - Couverture ≥ 80%

- [ ] **5.1.3** Tests unitaires `BudgetService`
  - Test calculs : spent, remaining, %
  - Test alertes 90%, 100%
  - Test avec valeurs edge (budget = 0, négatif)
  - Couverture ≥ 80%

- [ ] **5.1.4** Tests unitaires `AlertService`
  - Test génération alertes péremption
  - Test fusion avec `AlertStateRepository`
  - Test logique "lu" / "résolu"
  - Couverture ≥ 80%

- [ ] **5.1.5** Tests d'intégration flux principal
  - Onboarding → Ajouter produit → Voir inventaire → Budget
  - Vérifier données persistées
  - Vérifier navigation correcte

- [ ] **5.1.6** Tests widgets critiques
  - `DashboardScreen`
  - `AddProductScreen`
  - `BudgetScreen`
  - `SettingsScreen`

#### Tests pour Task 5.1
- [ ] **Test 5.1.T1** : Coverage globale ≥ 70%
- [ ] **Test 5.1.T2** : Tous les tests passent en CI (si configuré)
- [ ] **F2P Check** : Tests réellement validés (pas de faux positifs)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

## Phase 6: Publication (Semaines 12-13)

### Task 6.1: Préparation Stores

**Liée à** : Requirement V1.11 (Store Compliance)

- [ ] **6.1.1** Screenshots App Store/Play Store
  - Créer 5+ screenshots par plateforme
  - iPhone, iPad, Android phone, Android tablet
  - Localiser en FR (et EN si possible)

- [ ] **6.1.2** Vidéo démo 30-60s
  - Scénario : ouverture app → ajout produit → budget
  - Enregistrer écran
  - Ajouter sous-titres FR
  - Exporter pour iOS/Android

- [ ] **6.1.3** Description optimisée SEO
  - Mots-clés : inventaire, budget, Cameroun, maison, gestion
  - Description FR claire, <4000 chars
  - Traduire en EN

- [ ] **6.1.4** Soumettre à App Store
  - Créer app dans App Store Connect
  - Uploader build via Xcode/Transporter
  - Remplir metadata
  - Soumettre pour review

- [ ] **6.1.5** Soumettre à Play Store
  - Créer app dans Play Console
  - Uploader AAB via console
  - Remplir metadata
  - Soumettre pour review

#### Tests pour Task 6.1
- [ ] **Test 6.1.T1** : Build release iOS réussit et fonctionne
- [ ] **Test 6.1.T2** : Build release Android réussit et fonctionne
- [ ] **F2P Check** : App installable sur vrai device iOS/Android (test manuel)
- [ ] **P2F Check** : `flutter test` passe à 100%

---

**FIN DES TASKS V1**

---

## Notes pour l'IA (Cline/Cursor/Windsurf)

- Travailler UNIQUEMENT sur les tâches V1 sauf instruction contraire.
- Chaque tâche doit passer F2P + P2F avant d'être marquée DONE.
- Respecter AI_RULES.md : code efficient, idiomatique Dart, pas de nouveaux fichiers si existant utilisable.
- Avant de créer un service, vérifier si `lib/services/X_service.dart` existe déjà.
- Toujours écrire les tests AVANT de marquer la tâche terminée.

## 📝 Notes Importantes

1. **Commits à éviter** : Tous les commits avec "Co-authored-by: qodo-merge-pro[bot]"
2. **Priorité** : Se concentrer d'abord sur les fonctionnalités core (base de données, budget)
3. **Testing** : Implémenter les tests en même temps que les fonctionnalités
4. **Documentation** : Mettre à jour la documentation pour chaque fonctionnalité
5. **Performance** : Optimiser les performances dès le départ

---

*Document généré le 13 septembre 2025 - Version 1.0*
