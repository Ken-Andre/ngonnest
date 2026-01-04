# NGONNEST – REQUIREMENTS DOCUMENT

## Introduction

Ce document définit les exigences pour NgonNest, organisées par phase de développement :
- **V1 (MVP OFFLINE-ONLY)** : Fonctionnalités essentielles, 100% offline, publiable stores
- **V2 (POST-MVP)** : Améliorations UX, IA on-device, monétisation
- **V3+ (LONG-TERME)** : Cloud sync, multi-device, mode entreprise

**Règle pour l'IA** : Par défaut, travailler UNIQUEMENT sur requirements V1.* sauf instruction contraire explicite.

## Glossary

- **Feature Flags** : Mécanisme d'activation/désactivation conditionnelle de fonctionnalités
- **Offline-first** : Architecture où l'app fonctionne entièrement sans Internet
- **SQLite** : Base de données locale (source de vérité V1)
- **Supabase** : Backend cloud (V3+ uniquement, opt-in)
- **RegionConfig** : Abstraction multi-pays/devises
- **F2P** : False-to-Positive (vérification fonctionnelle réelle)
- **P2F** : Pass-to-Fail (tests automatisés 100%)
- **FCFA/XAF** : Franc CFA, devise du Cameroun
- **NGN** : Naira, devise du Nigeria

---

# V1 – MVP OFFLINE-ONLY REQUIREMENTS

## Requirement V1.1: Security and Configuration Management

**Phase** : V1 – CRITIQUE  
**User Story** : En tant que développeur, je veux que les clés API soient sécurisées et que les builds soient configurés correctement pour différents environnements, afin de protéger les informations sensibles et faciliter le développement.

### Acceptance Criteria

1. WHEN building for any environment THEN Supabase API keys SHALL be stored in `.env` files (flutter_dotenv), not in source code
2. WHEN building for release THEN code obfuscation SHALL be applied to protect intellectual property
3. WHEN building the app THEN separate configurations (dev/prod) SHALL exist via environment variables
4. WHEN accessing credentials THEN they SHALL be retrieved from secure environment variables via EnvConfig service
5. WHEN building for release THEN no sensitive information SHALL be exposed in compiled binary
6. WHEN `.env` file is missing THEN app SHALL fail gracefully with clear error message

---

## Requirement V1.2: Feature Flags System

**Phase** : V1 – CRITIQUE  
**User Story** : En tant que développeur, je veux un système de feature flags robuste, afin de désactiver proprement les fonctionnalités non prêtes (cloud sync, premium) tout en préservant le code pour le futur.

### Acceptance Criteria

1. WHEN implementing feature flags THEN a `FeatureFlagService` SHALL exist as singleton
2. WHEN in V1 release mode THEN `isCloudSyncEnabled` SHALL return `false`
3. WHEN in V1 release mode THEN `isPremiumEnabled` SHALL return `false`
4. WHEN in dev/debug mode THEN `isCloudSyncEnabled` MAY return `true` for testing infrastructure
5. WHEN a feature is disabled THEN UI SHALL NOT call the associated services
6. WHEN displaying disabled features THEN they SHALL be hidden OR grayed with tooltip "Bientôt disponible"
7. WHEN switching build configurations THEN feature flags SHALL adapt automatically based on build mode

---

## Requirement V1.3: Alert Persistence System

**Phase** : V1 – CRITIQUE  
**User Story** : En tant qu'utilisateur, je veux que l'état de mes alertes (lu/résolu) soit persisté localement, afin de ne pas revoir constamment les mêmes alertes après redémarrage de l'application.

### Acceptance Criteria

1. WHEN upgrading the app THEN a SQLite migration SHALL create `alert_states` table with proper schema
2. WHEN marking an alert as read THEN its state SHALL be saved in `alert_states` table
3. WHEN marking an alert as resolved THEN its state SHALL be saved in `alert_states` table
4. WHEN loading alerts THEN their read/resolved states SHALL be retrieved from database and merged
5. WHEN displaying 100+ alerts THEN UI SHALL remain responsive (<2s load time, smooth scroll)
6. WHEN marking an alert state THEN visual feedback SHALL be immediate (animation, icon change)
7. WHEN querying alert_states THEN performance SHALL be acceptable with 1000+ records (proper indexes)

---

## Requirement V1.4: Offline Inventory Management (CRUD Complete)

**Phase** : V1 – CRITIQUE  
**User Story** : En tant qu'utilisateur, je veux gérer mon inventaire domestique entièrement hors ligne (créer, lire, modifier, supprimer, rechercher), afin de suivre mes produits même sans connexion Internet.

### Acceptance Criteria

1. WHEN adding a product THEN it SHALL be immediately saved to SQLite with all fields
2. WHEN viewing inventory THEN all products SHALL load from local database
3. WHEN editing a product THEN changes SHALL persist to SQLite
4. WHEN deleting a product THEN it SHALL be removed from local database (with confirmation dialog)
5. WHEN searching inventory THEN results SHALL come from SQLite queries (LIKE pattern)
6. WHEN the app restarts THEN all inventory data SHALL persist correctly
7. WHEN no Internet connection THEN all inventory features SHALL work normally without error

---

## Requirement V1.5: Basic Budget Management (Offline)

**Phase** : V1 – CRITIQUE  
**User Story** : En tant qu'utilisateur, je veux définir un budget mensuel et suivre mes dépenses simples, afin de gérer mes finances domestiques et éviter les dépenses excessives.

### Acceptance Criteria

1. WHEN setting monthly budget THEN it SHALL be stored in SQLite with household_id, month, year
2. WHEN adding products with prices THEN spending SHALL be automatically tracked locally
3. WHEN viewing budget THEN simple summary SHALL show: total budget, spent amount, remaining amount
4. WHEN budget data changes THEN calculations SHALL update immediately in UI
5. WHEN spending reaches 90% of budget THEN an alert SHALL be triggered
6. WHEN spending exceeds 100% of budget THEN an alert SHALL be shown
7. WHEN no Internet THEN budget features SHALL work fully offline

---

## Requirement V1.6: Price Database (Cameroon + Multi-Region Ready)

**Phase** : V1 – CRITIQUE  
**User Story** : En tant qu'utilisateur camerounais, je veux des prix locaux réalistes pour les produits courants, afin de budgétiser correctement. En tant que développeur, je veux une structure extensible pour supporter d'autres pays facilement.

### Acceptance Criteria

1. WHEN the app starts THEN `RegionConfig` SHALL detect user's country (via locale or manual selection)
2. WHEN in Cameroon THEN prices SHALL be in XAF (FCFA) with correct symbol
3. WHEN in Nigeria THEN prices SHALL be in NGN (Naira) with ₦ symbol
4. WHEN pricing data is missing for a product THEN user SHALL be able to enter price manually
5. WHEN displaying prices THEN correct currency symbol SHALL be used based on RegionConfig
6. WHEN database contains pricing data THEN at least 500 common Cameroon products SHALL have verified prices
7. WHEN prices are outdated THEN a manual update mechanism SHALL exist (admin/CSV import for V1)

---

## Requirement V1.7: Simple Onboarding Flow

**Phase** : V1 – IMPORTANT  
**User Story** : En tant que nouvel utilisateur, je veux un onboarding rapide et clair (3-4 écrans), afin de comprendre comment utiliser l'application en moins de 2 minutes.

### Acceptance Criteria

1. WHEN launching app for first time THEN 3-4 onboarding slides SHALL be displayed
2. WHEN viewing onboarding THEN slides SHALL explain: inventory management, budget tracking, smart alerts
3. WHEN viewing onboarding THEN a "Passer" (Skip) button SHALL be available on each slide
4. WHEN completing onboarding THEN household profile setup SHALL be simple (sliders/dropdowns, not complex forms)
5. WHEN onboarding finishes THEN user SHALL land directly on main dashboard
6. WHEN app is reopened THEN onboarding SHALL NOT show again (state saved in SharedPreferences)

---

## Requirement V1.8: User-Friendly Error Messages

**Phase** : V1 – IMPORTANT  
**User Story** : En tant qu'utilisateur non technique, je veux des messages d'erreur clairs en français, afin de comprendre les problèmes et savoir quoi faire.

### Acceptance Criteria

1. WHEN an error occurs THEN `ErrorMessageService` SHALL provide user-friendly French messages
2. WHEN displaying errors THEN technical stack traces SHALL be logged but NOT shown to users
3. WHEN showing errors THEN actionable solutions SHALL be suggested (e.g., "Vérifiez votre saisie")
4. WHEN testing with non-technical users THEN error message clarity SHALL be validated
5. WHEN common errors occur THEN illustrations MAY be shown to help communicate visually
6. WHEN errors are logged THEN `ErrorLoggerService` SHALL capture details for debugging without exposing to user

---

## Requirement V1.9: Functional Quick Actions (Dashboard)

**Phase** : V1 – IMPORTANT  
**User Story** : En tant qu'utilisateur régulier, je veux accéder rapidement aux fonctions principales depuis le dashboard, afin de gagner du temps dans mes tâches quotidiennes.

### Acceptance Criteria

1. WHEN viewing dashboard THEN quick actions SHALL navigate to: Add Product, View Inventory, Budget, Settings
2. WHEN tapping quick actions THEN navigation SHALL work correctly on iOS and Android
3. WHEN displaying quick actions THEN icons and labels SHALL be clear and localized (French)
4. WHEN testing THEN no navigation dead-ends SHALL exist (all buttons lead somewhere functional)
5. WHEN designing quick actions THEN they SHALL be easily tappable (minimum 44x44 iOS, 48x48 Android)
6. WHEN using quick actions THEN semantic labels SHALL be present for accessibility

---

## Requirement V1.10: Performance Optimization (Low-End Devices)

**Phase** : V1 – IMPORTANT  
**User Story** : En tant qu'utilisateur avec un appareil ancien (Android 8.0, 2GB RAM), je veux que l'application soit fluide, afin de pouvoir l'utiliser sans frustration.

### Acceptance Criteria

1. WHEN loading dashboard with 500+ products THEN load time SHALL be < 2 seconds
2. WHEN scrolling lists THEN UI SHALL remain responsive at 60fps
3. WHEN app is idle THEN battery drain SHALL be < 1%/hour
4. WHEN testing on Android 8.0 devices THEN all features SHALL work correctly
5. WHEN profiling memory THEN no memory leaks SHALL be detected after 30 minutes usage
6. WHEN displaying large lists THEN lazy loading/pagination SHALL be implemented

---

## Requirement V1.11: Store Compliance (Apple/Google)

**Phase** : V1 – CRITIQUE  
**User Story** : En tant que Product Manager, je veux que l'application soit publiable sur App Store et Google Play sans rejet, afin de garantir un lancement réussi.

### Acceptance Criteria

1. WHEN submitting to Apple App Store THEN app SHALL meet all App Store Review Guidelines
2. WHEN submitting to Google Play THEN app SHALL meet all Play Store policies
3. WHEN reviewed THEN Privacy Policy SHALL be accessible and complete
4. WHEN reviewed THEN no fake/non-functional features SHALL be accessible to users
5. WHEN tested THEN app SHALL not crash on standard user flows
6. WHEN checked THEN all visible buttons SHALL have real, functional implementations

---

# V2 – POST-MVP REQUIREMENTS

## Requirement V2.1: Budget Graphs & Visualization

**Phase** : V2  
**User Story** : En tant qu'utilisateur attentif à mes finances, je veux visualiser mes dépenses mensuelles en graphiques (barres, camemberts), afin de mieux comprendre mes habitudes de consommation.

### Acceptance Criteria

1. WHEN viewing budget screen THEN monthly expense graphs SHALL be available
2. WHEN displaying graphs THEN data SHALL come from local SQLite
3. WHEN interacting with graphs THEN they SHALL be responsive and smooth
4. WHEN viewing categories THEN breakdown by category SHALL be shown visually
5. WHEN selecting a month THEN historical data SHALL be displayed

---

## Requirement V2.2: PDF Export (Budget Reports)

**Phase** : V2  
**User Story** : En tant qu'utilisateur organisé, je veux exporter mes rapports budgétaires en PDF, afin de les partager ou les archiver.

### Acceptance Criteria

1. WHEN requesting export THEN a PDF SHALL be generated locally (no cloud dependency)
2. WHEN exporting THEN PDF SHALL contain budget summary, expenses by category, and totals
3. WHEN exported THEN file SHALL be shareable via native share dialog
4. WHEN generating PDF THEN formatting SHALL be clean and professional
5. WHEN PDF is created THEN it SHALL be saved to user-accessible location

---

## Requirement V2.3: On-Device AI (Consumption Prediction)

**Phase** : V2  
**User Story** : En tant qu'utilisateur régulier, je veux que l'application prédise quand je vais manquer de produits, afin de mieux planifier mes achats.

### Acceptance Criteria

1. WHEN using app regularly THEN consumption patterns SHALL be learned locally (no cloud)
2. WHEN predictions are made THEN they SHALL use on-device ML (TensorFlow Lite or similar)
3. WHEN displaying predictions THEN they SHALL be presented as suggestions, not absolute facts
4. WHEN ML model runs THEN battery/performance impact SHALL be minimal
5. WHEN insufficient data THEN predictions SHALL not be shown (graceful degradation)

---

## Requirement V2.4: Premium Features (One-time Purchase or Subscription)

**Phase** : V2  
**User Story** : En tant que développeur, je veux monétiser l'application via un achat unique ou abonnement, afin de générer des revenus tout en gardant les fonctionnalités de base gratuites.

### Acceptance Criteria

1. WHEN implementing premium THEN RevenueCat SHALL be integrated
2. WHEN purchasing THEN options SHALL include: one-time payment (5000 FCFA) OR subscription (500 FCFA/month)
3. WHEN premium is active THEN advanced features SHALL unlock (AI predictions, PDF export, graphs avancés)
4. WHEN not premium THEN core features SHALL remain fully functional (inventory, budget basique, alertes)
5. WHEN transaction fails THEN error handling SHALL be graceful with retry option

---

## Requirement V2.5: Advanced Micro-interactions

**Phase** : V2  
**User Story** : En tant qu'utilisateur moderne, je veux une expérience fluide avec animations et retours tactiles, afin que l'utilisation soit agréable.

### Acceptance Criteria

1. WHEN pressing important buttons THEN haptic feedback SHALL be provided
2. WHEN completing actions THEN success/failure animations SHALL give visual feedback
3. WHEN achieving budget goals THEN celebrations (confetti) SHALL reward user
4. WHEN loading data THEN skeleton screens SHALL indicate content is coming
5. WHEN interacting THEN micro-interactions SHALL feel responsive and delightful

---

## Requirement V2.6: Simplified Mode (Beginner vs Advanced)

**Phase** : V2  
**User Story** : En tant qu'utilisateur non technique, je veux un mode simplifié de l'application, afin de ne pas me sentir perdu par trop d'options.

### Acceptance Criteria

1. WHEN accessing settings THEN `PreferencesService` SHALL manage UI complexity modes
2. WHEN selecting beginner mode THEN simplified forms and clear labels SHALL be displayed
3. WHEN choosing advanced mode THEN all functionality SHALL be available
4. WHEN switching modes THEN transition SHALL be seamless without data loss
5. WHEN needing help THEN integrated tutorial SHALL be activable anytime

---

# V3+ – LONG-TERM REQUIREMENTS

## Requirement V3.1: Cloud Sync (Supabase, Opt-In)

**Phase** : V3  
**User Story** : En tant qu'utilisateur multi-device, je veux synchroniser mes données entre mes appareils (téléphone, tablette), afin de ne pas perdre d'information.

### Acceptance Criteria

1. WHEN opting in THEN user SHALL give explicit consent for cloud sync with privacy explanation
2. WHEN syncing THEN SQLite SHALL remain source of truth with queue-based sync
3. WHEN offline THEN app SHALL continue working and queue sync operations
4. WHEN conflicts occur THEN resolution strategy SHALL be applied (local wins by default)
5. WHEN syncing THEN encryption SHALL be used for data in transit and at rest

---

## Requirement V3.2: Family Sharing & Multi-User

**Phase** : V3  
**User Story** : En tant que famille, nous voulons partager un inventaire commun et voir qui a ajouté quoi.

### Acceptance Criteria

1. WHEN sharing THEN multiple users SHALL access same household data
2. WHEN collaborating THEN changes SHALL sync in near-real-time
3. WHEN managing access THEN household admin SHALL control permissions
4. WHEN viewing history THEN user who made change SHALL be visible

---

## Requirement V3.3: Hotel/Restaurant Mode (Enterprise)

**Phase** : V3  
**User Story** : En tant que gérant d'hôtel, je veux gérer l'inventaire de plusieurs chambres/espaces, afin d'optimiser mes stocks.

### Acceptance Criteria

1. WHEN in enterprise mode THEN multiple spaces SHALL be manageable
2. WHEN reporting THEN advanced analytics SHALL be available
3. WHEN integrating THEN WhatsApp Business connection SHALL be possible for notifications
4. WHEN managing staff THEN role-based access SHALL be configurable

---

# TESTING REQUIREMENTS (All Phases)

## Requirement TEST.1: Automated Testing Coverage

**Phase** : V1 – CRITIQUE  
**User Story** : En tant que développeur, je veux une couverture de tests élevée, afin d'assurer la qualité et détecter les régressions automatiquement.

### Acceptance Criteria

1. WHEN running tests THEN unit test coverage SHALL be ≥ 80% for services/repositories
2. WHEN testing DatabaseService THEN all CRUD operations and migrations SHALL be covered
3. WHEN testing BudgetService THEN all calculations and alert logic SHALL be verified
4. WHEN testing AlertGenerationService THEN all alert scenarios SHALL be covered
5. WHEN testing widgets THEN critical screens SHALL have widget tests
6. WHEN testing flows THEN integration tests SHALL cover main user journeys
7. WHEN measuring coverage THEN overall code coverage SHALL exceed 70%

---

## Requirement TEST.2: Performance Testing

**Phase** : V1 – IMPORTANT  
**User Story** : En tant que QA, je veux valider la performance sur appareils bas de gamme, afin d'assurer une expérience fluide pour tous les utilisateurs.

### Acceptance Criteria

1. WHEN profiling with 1000+ products THEN performance SHALL be measured and acceptable
2. WHEN monitoring THEN memory leaks SHALL be detected and fixed
3. WHEN testing battery THEN drain SHALL be kept within acceptable limits (<1%/h idle)
4. WHEN testing on low-end devices THEN Android 8.0+ compatibility SHALL be ensured
5. WHEN benchmarking THEN consistent performance metrics SHALL be established

---

**FIN DU DOCUMENT**

---

**Notes pour l'IA** :
- Travailler sur V1.* uniquement sauf instruction contraire
- Chaque requirement a un ID clair (V1.X, V2.X, V3.X) pour traçabilité
- Les acceptance criteria sont testables et non ambigus
- Respecter AI_RULES.md pour toute implémentation
