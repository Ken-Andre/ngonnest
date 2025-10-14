# RULES.md

Ce document consolide les règles d’ingénierie pour `ngonnest`.
Il complète `AGENTS.md` par des conventions opérationnelles, sécurité et qualité.

## 1. Architecture & principes
- **Offline‑first**: la base locale (SQLite) est source de vérité. La synchronisation est optionnelle, non bloquante, avec « local wins ».
- **Séparation des responsabilités**: 
  - `services/` logiques transverses (sync, budget, permissions, notifications…).
  - `repository/` accès DB par agrégat (foyer, inventaire).
  - `models/` types immuables, `copyWith`, sérialisation.
  - `widgets/screens/` UI uniquement, pas de SQL.
- **Erreurs & logs**: centraliser via `ErrorLoggerService` avec `severity` et `metadata`. Pas de secrets dans les logs.

## 2. Conventions code Dart/Flutter
- Null‑safety obligatoire. `late` réservé aux invariants.
- Nommage: fichiers `snake_case.dart`, classes `PascalCase`, variables `camelCase`.
- I18n: toute chaîne affichée passe par `l10n`. Pas de hard‑coded strings.
- Accessibilité: labels sémantiques, contrastes, tailles tactiles (≥ 44x44), navigation clavier.
- UI réactive: pas de blocage UI pour I/O; utiliser `Future`, `Isolates` si besoin.

## 3. Base de données
- Migrations versionnées dans `DatabaseService`.
- Colonnes et tables en `snake_case`. Indexer les colonnes filtrées fréquemment.
- Écrire des tests pour chaque migration et pour l’export/import JSON.
- Noms de colonnes alignés aux modèles (`Objet`, `Foyer`, `BudgetCategory`).

## 4. Synchronisation
- Stratégie: 
  - File d’outbox locale (création/màj/suppression) + horodatage.
  - Retry exponentiel (2^n s, max 3 tentatives), backoff sur erreurs réseau.
  - Conflits: dernier `updatedAt` gagne; journaliser les divergences.
  - Respect consentement utilisateur avant tout envoi.
- Tests: 
  - Hors‑ligne complet, retour en ligne, erreurs réseau simulées.
  - Idempotence des opérations.

## 5. Budget & prix
- `BudgetService` seule source pour calculs/alertes.
- `PriceService` fournit prix moyens par catégorie/pays et estimation par article.
- Les écrans appellent `BudgetService.checkBudgetAlertsAfterPurchase` après ajout/mise à jour d’objets.

## 6. Permissions & notifications
- Demandes de permissions encapsulées (`NotificationPermissionService`, `CalendarSyncService`).
- Plateforme:
  - Android 13+: granularité photos/vidéos/audio pour stockage; fallback `storage`.
  - iOS: vérifier le résultat `CalendarPermission`.
  - Web/Desktop: chemins gracefull → retour faux, message à l’utilisateur.

## 7. Sécurité & confidentialité
- Aucune donnée sensible en clair dans les logs, exports, captures d’erreurs.
- Télémetrie: opt‑in explicite; premier démarrage sans envoi; anonymisée.
- Secrets/API keys via variables d’environnement, jamais commités.
- Export JSON: documenter le schéma, versionner, et chiffrer côté utilisateur si nécessaire.

## 8. Qualité & CI locale
- Avant commit: format, analyse, tests. 
- Écriture de tests: 
  - Services critiques (sync, budget, DB) ≥ 80% couverture lignes.
  - Tests d’intégration pour flux: onboarding → ajout produit → alerte budget → export.
- Linting: respecter `analysis_options.yaml`; ajouter règles spécifiques au besoin.

## 9. Git & branches
- Convention branches: `feature/...`, `fix/...`, `chore/...`.
- Messages de commit orientés « pourquoi », concis.
- PR obligatoires vers `main`, description claire, checklist DoD, tests verts.

## 10. Roadmap MVP (tech)
- Stabiliser `SyncService` (remplacer placeholder `_syncData`).
- Nettoyer `CalendarSyncService._requestPermissions` et scénarios d’échec.
- Finaliser actions HTTP/Telegram dans `SettingsScreen`.
- Harmoniser types dans `ProductSuggestionService` (ID foyer int), normaliser catégories/units.
- Étendre `PriceService` + données `config/cameroon_prices.dart`.
- Onboarding: compléter profil foyer (personnes, pièces, tailles), alimenter `HouseholdService`.

## 11. Revue de code
- Chaque PR: lecture croisée, vérif i18n/a11y, logs, erreurs.
- Refus si: UI avec chaînes en dur, absence de tests, prints non nécessaires, dette non justifiée.

## 12. Definition of Ready (DoR)
- User story claire, critères d’acceptation listés.
- Impacts data/i18n/a11y identifiés.
- Stratégie de test prévue (unit + intégration).

## 13. Definition of Done (DoD)
- Code mergé, tests verts, docs mises à jour (`AGENTS.md`/`RULES.md`/README si utile).
- Télémetrie/erreurs observables, sans fuite d’infos.
- Fonctionne hors‑ligne, comportements dégradés documentés.
