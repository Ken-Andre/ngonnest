# NGONNEST – RÈGLES FONDAMENTALES (SOURCE DE VÉRITÉ)

## 0. Chronologie Produit (Roadmap)

### V1 (MVP – OFFLINE ONLY)
**Objectif**: Application 100% fonctionnelle, offline-first, publiable sur stores  
**Durée estimée**: 12-16 semaines  
**Scope**:
- 100% offline (aucune dépendance réseau obligatoire)
- Inventaire complet (CRUD + recherche)
- Budget basique (définition + suivi simple)
- Alertes persistantes (péremption + rupture)
- Prix locaux multi-pays (Cameroun + structure extensible)
- UX claire (onboarding, messages d'erreur FR, quick actions)
- Performance optimisée (devices bas de gamme)
- Store-ready (Apple + Google compliance)

### V2 (Post-MVP)
**Objectif**: Améliorations UX + monétisation + IA on-device  
**Scope**:
- Graphiques budget (visualisations mensuelles)
- Export PDF (rapports budgétaires)
- IA on-device (prédiction consommation, TensorFlow Lite)
- Premium features (RevenueCat, achat unique ou abonnement)
- Micro-interactions avancées
- Mode simplifié vs avancé

### V3+ (Long terme)
**Objectif**: Cloud + multi-device + entreprise  
**Scope**:
- Cloud sync (Supabase, opt-in explicite)
- Multi-device + partage famille
- Mode hôtel/restaurant (gestion multi-espaces)
- Analytics avancées
- Intégration WhatsApp Business

## 1. Principes d'Architecture

### Offline-First (Non négociable V1)
- SQLite = source de vérité unique
- L'application fonctionne entièrement sans Internet
- Toute sync cloud future sera optionnelle et derrière feature flag
- Pattern: local wins en cas de conflit

### Séparation des Responsabilités
```
UI Layer (widgets/screens/)
    ↓
Business Logic Layer (services/)
    ↓
Data Layer (repositories/)
    ↓
Data Sources (SQLite, future: Supabase)
```

### Multi-Région Ready
- Toute logique dépendante du pays/devise passe par `RegionConfig`
- Support: Cameroun (XAF), Nigeria (NGN), extensible
- Prix locaux par pays avec fallback

## 2. Feature Flags (Obligatoire)

### Service FeatureFlagService
Doit exposer:
- `bool isCloudSyncEnabled`
- `bool isPremiumEnabled`
- `bool isExperimentalFeaturesEnabled`

### États par Version
**V1**:
- `isCloudSyncEnabled = false`
- `isPremiumEnabled = false`

**V2**:
- `isPremiumEnabled = true` (si implémenté)

**V3**:
- `isCloudSyncEnabled = true` (si opt-in utilisateur)

### Comportement UI
- Si flag = false:
  - Option cachée OU grisée avec tooltip "Bientôt disponible"
  - Aucun appel au service associé

## 3. Conventions Code (Dart/Flutter)

### Nommage
- Fichiers: `snake_case.dart`
- Classes: `PascalCase`
- Variables/méthodes: `camelCase`
- Constantes: `SCREAMING_SNAKE_CASE`

### Null-Safety Stricte
- Éviter `!` (bang operator) autant que possible
- Préférer `?.` et `??`
- `late` uniquement pour invariants clairement documentés

### Typage Fort
- Pas de `dynamic` sans justification solide dans commentaire
- Préférer types explicites
- Utiliser génériques quand approprié

### Gestion d'Erreurs
- Services ne jettent PAS d'exceptions brutes vers UI
- Pattern `Result<T, Failure>` ou `Either<L, R>` recommandé
- Logging via `ErrorLoggerService`
- Messages user-friendly via `ErrorMessageService`

### Internationalisation (i18n)
- TOUS les textes UI via `l10n` (AppLocalizations)
- Aucune chaîne hardcodée en français/anglais
- Support minimum: FR, EN (ES recommandé)

### Accessibilité
- Labels sémantiques pour screen readers
- Contraste ≥ 4.5:1 (WCAG AA)
- Taille tactile minimum 44x44 (iOS) / 48x48 (Android)
- Navigation clavier supportée

## 4. Base de Données (SQLite)

### Migrations
- Versionnées dans `DatabaseService`
- Testées sur base vide ET upgrade
- Chaque migration documentée avec commentaire

### Conventions
- Tables/colonnes: `snake_case`
- Index sur colonnes filtrées fréquemment
- Contraintes de clés étrangères actives

### Tests Requis
- Migration base vide
- Migration upgrade depuis version précédente
- CRUD operations
- Export/import JSON

## 5. Gestion des Fichiers (Crucial pour IA)

### L'IA NE DOIT PAS
- Créer nouveau fichier si existant approprié
- Dupliquer concepts (pas de `NewXService` si `XService` existe)
- Ajouter fichiers sans justification claire

### L'IA DOIT
- Chercher fichier existant approprié AVANT création
- Étendre/refactoriser intelligemment fichiers actuels
- Proposer modification minimale cohérente
- Justifier création nouveau fichier dans commit message

### Exemples
**Mauvais**:
- Créer `new_budget_service.dart` alors que `budget_service.dart` existe

**Bon**:
- Étendre `budget_service.dart` avec nouvelles méthodes
- Refactoriser en sous-modules si fichier > 500 lignes

## 6. Code Moderne et Efficient

### Idiomatique Dart/Flutter
- Utiliser features modernes (null-safety, extensions, etc.)
- Pas de code obsolète ou deprecated
- Préférer version concise MAIS lisible

### Exemples
**Mauvais**:
```dart
String result;
if (condition) {
  result = "A";
} else {
  result = "B";
}
```

**Bon**:
```dart
final result = condition ? "A" : "B";
```

**Mauvais**:
```dart
List<Product> filtered = [];
for (var p in products) {
  if (p.category == "Food") {
    filtered.add(p);
  }
}
```

**Bon**:
```dart
final filtered = products.where((p) => p.category == "Food").toList();
```

## 7. Qualité & Tests

### F2P (False-to-Positive)
Vérification: "Le code fait-il VRAIMENT ce qui est décrit ?"
- Test fonctionnel manuel
- Pas de faux positif (test vert pour mauvaise raison)

### P2F (Pass-to-Fail)
Vérification: "`flutter test` passe-t-il à 100% ?"
- Tous les tests unitaires passent
- Tous les tests widgets passent
- Tous les tests d'intégration passent
- Aucune régression

### Couverture Minimum
- Services critiques: ≥ 80%
- Repositories: ≥ 80%
- Couverture globale: ≥ 70%

### Types de Tests
- **Unit**: Services, repositories, modèles
- **Widget**: Écrans critiques, composants réutilisables
- **Integration**: Flux utilisateur principaux

## 8. Sécurité & Privacy

### Secrets
- Aucune clé API en code source
- Utiliser `.env` via `flutter_dotenv`
- `.env` dans `.gitignore`
- `.env.example` versionné (valeurs vides)

### Données Utilisateur
- Toutes locales en V1
- Cryptage AES-256 si données sensibles
- Aucun log de données personnelles
- Consentement explicite avant toute sync cloud (V3)

### Permissions
- Demande minimale
- Justification claire à l'utilisateur
- Gestion gracieuse des refus

## 9. Performance

### Cibles V1
- Dashboard: charge < 2s avec 500+ produits
- Scroll: 60fps maintenu
- Batterie: < 1%/h en idle
- Compatibilité: Android 8.0+ (API 26+)

### Optimisations
- Lazy loading pour listes longues
- Pagination (50 items par page recommandé)
- Cache pour calculs fréquents
- Indexes SQLite appropriés

## 10. Rôle de l'IA (Cline/Cursor/Windsurf)

### L'IA DOIT
- Lire AI_RULES.md avant modification importante
- Respecter phase actuelle (V1 par défaut)
- Travailler par petites PR ciblées
- Écrire tests AVANT de marquer tâche DONE
- Suivre format exact de tasks_vX.md

### L'IA NE DOIT PAS
- Introduire features non demandées
- Activer cloud/premium sans mise à jour règles
- Modifier schéma DB sans migration
- Créer fichiers sans nécessité
- Utiliser code obsolète ou verbeux

## 11. Décisions Non Négociables V1

### Offline-Only
- Aucune fonction critique ne dépend d'Internet
- Toutes les données persistées localement
- App fonctionne en mode avion

### Pas de Fausses Promesses
- Pas de bouton "Premium" cliquable si non implémenté
- Pas de "Cloud Sync" actif
- Pas de "IA" si non fonctionnelle
- Features désactivées = cachées OU clairement marquées "Bientôt"

### Données Locales
- SQLite source de vérité
- Export/import JSON pour backup utilisateur
- Aucune télémétrie sans opt-in explicite

## 12. Validation Critère Ultime

**Test de la Mère Camerounaise**:  
"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"

Si NON → simplifier ou repenser UX.
