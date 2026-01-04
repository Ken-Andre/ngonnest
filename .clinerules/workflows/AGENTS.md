# AGENTS.md – Règles pour Agents IA (Cline/Cursor)

## Portée
Ces consignes s'appliquent à tout le dépôt `ngonnest`.
Tu les suis strictement dès que tu touches un fichier.

---

## Workflow Avant Commit

Avant CHAQUE commit, tu DOIS exécuter :

```bash
flutter format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Si build_runner nécessaire (mocks changés) :
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Règle d'or** : Aucun commit si tests échouent ou analyze a des erreurs.

---

## Style & Conventions

### Code Dart/Flutter
- **Null-safety** obligatoire, stricte
- **Fichiers** : `snake_case.dart`
- **Classes** : `PascalCase`
- **Variables/méthodes** : `camelCase`
- **Constantes** : `SCREAMING_SNAKE_CASE`

### Documentation
- Commentaires doc (`///`) pour APIs publiques
- Pas de `print()` en code de production (utiliser `ErrorLoggerService` ou `console_logger`)

### Internationalisation
- **Tous** les textes UI via `l10n` (AppLocalizations)
- Jamais de chaînes hardcodées en français/anglais dans le code

### Commits
- Un commit = une idée/tâche
- Sujet ≤ 72 caractères, présent, sans point final
- Format : `type(scope): description`
  - Exemples : `feat(budget): add 90% alert`, `fix(inventory): correct delete logic`, `test(alert): add persistence tests`

### Branches
- Nommage : `feature/...`, `fix/...`, `chore/...`, `task/...`
- PR vers `main` avec tests verts obligatoires

---

## Fichiers Source de Vérité

Avant toute modification importante, **LIRE** :

1. **AI_RULES.md** - Constitution du projet, roadmap V1/V2/V3
2. **requirements.md** - Requirements par phase
3. **tasks_v1.md** (ou v2/v3) - Tâches détaillées

En cas de conflit : **AI_RULES.md > requirements.md > tasks_vX.md**.

---

## Gestion d'État avec Provider

- Utiliser `ChangeNotifierProvider` pour états mutables
- Utiliser `Provider` pour services singleton
- Éviter `Consumer` imbriqués → préférer `context.watch<T>()`
- Dispose correctement providers dans `dispose()`

---

## Base de Données & Modèles

### SQLite
- Base locale avec `sqflite`
- Modèles avec `toMap()` et `fromMap()` obligatoires
- Migrations versionnées dans `DatabaseService`
- Indexes sur clés étrangères et champs de recherche
- Cryptage AES-256 pour données sensibles (si applicable)

### Conventions
- Tables/colonnes : `snake_case`
- Noms alignés aux modèles (`Objet`, `Foyer`, `BudgetCategory`)

---

## Services & Repository

### Pattern
- Un service par domaine métier (`HouseholdService`, `BudgetService`, `AlertService`)
- Repository pour abstraction couche données
- Gestion d'erreur avec try/catch + `ErrorLoggerService`
- Méthodes async : `Future<T>` ou `Stream<T>`
- Validation paramètres en entrée

### Exemple
```dart
// lib/services/budget_service.dart
class BudgetService {
  final BudgetRepository _repo;
  final ErrorLoggerService _logger;

  Future<double> getTotalSpent(int householdId, int month, int year) async {
    try {
      return await _repo.getTotalSpent(householdId, month, year);
    } catch (e, stackTrace) {
      _logger.log(e, stackTrace, severity: Severity.error);
      rethrow;
    }
  }
}
```

---

## UI/UX Guidelines

### Design System
- Utiliser `AppTheme` pour cohérence
- **Responsive** : tester différentes tailles d'écran
- **Accessibilité** :
  - Contraste ≥ 4.5:1 (WCAG AA)
  - Taille police ≥ 16px
  - Labels sémantiques pour screen readers
  - Taille tactile ≥ 44x44 (iOS) / 48x48 (Android)

### Loading & Error States
- **Loading** : `CupertinoActivityIndicator` ou `CircularProgressIndicator`
- **Error** : Messages conviviaux avec `SnackBar` ou `Dialog`
- **Empty States** : Illustrations + call-to-action

---

## Internationalisation (i18n)

- Utiliser `flutter_localizations` et `intl`
- Clés en `camelCase` (ex: `welcomeMessage`)
- Support FR, EN, ES (extensible)
- Textes hardcodés interdits → utiliser `AppLocalizations.of(context)`

---

## Tests & Qualité

### Couverture Minimum
- **Services/Repositories** : ≥ 80%
- **Couverture globale** : ≥ 70%

### Types de Tests
- **Unit** : Services, repositories, modèles
- **Widget** : Widgets complexes, écrans critiques
- **Integration** : Flux utilisateur principaux
- **Mocks** : Utiliser `mockito` pour dépendances externes

### F2P & P2F
- **F2P** (False-to-Positive) : Code fait VRAIMENT ce qui est décrit (test manuel)
- **P2F** (Pass-to-Fail) : `flutter test` passe à 100% (régression check)

---

## Performance & Optimisation

### Cibles V1
- Dashboard charge < 2s avec 500+ produits
- Scroll 60fps maintenu
- Batterie < 1%/h en idle
- Compatibilité Android 8.0+ (API 26+)

### Techniques
- **Lazy loading** pour listes longues
- **Pagination** (50 items par page recommandé)
- **Image optimization** : compression + cache
- **Memory management** : dispose controllers/streams
- **Build optimization** : éviter rebuilds inutiles

---

## Sécurité & Privacy

### Secrets
- Aucune clé API en code source
- Utiliser `.env` via `flutter_dotenv`
- `.env` dans `.gitignore`

### Données
- **Cryptage** AES-256 si données sensibles
- **Permissions** : demande minimale + justification
- **Logs** : pas de données sensibles
- **Validation** : sanitize toutes entrées utilisateur

---

## Notifications & Background

- **Local notifications** : `flutter_local_notifications`
- **Background tasks** : `workmanager` pour tâches périodiques
- **Permissions** : gestion gracieuse des refus
- **Battery** : minimiser impact énergétique

---

## Connectivity & Sync

- **Offline first** : App fonctionnelle sans réseau
- **Sync optionnelle** : Avec consentement utilisateur (V3+)
- **Conflict resolution** : Local wins par défaut
- **Retry logic** : Exponential backoff pour échecs réseau

---

## Priorités Actuelles (MVP V1)

### À Finaliser AVANT Publication

1. **Security & Config** : Externaliser clés API (`.env`)
2. **Feature Flags** : Désactiver cloud sync/premium en V1
3. **Alert Persistence** : Migration + repository alert_states
4. **Inventory CRUD** : Audit et correction complète offline
5. **Budget Basique** : Calculs + alertes 90%/100%
6. **Prix Multi-Région** : RegionConfig + 500 produits Cameroun
7. **Onboarding** : 3-4 slides simples
8. **Error Messages** : Service messages FR user-friendly
9. **Quick Actions** : Dashboard navigation fonctionnelle
10. **Performance** : Tests 500+ produits <2s
11. **Store Compliance** : Checklist Apple/Google

### Résolu (Ne Plus Toucher)
- Route '/edit-objet' et écran associé : présents
- Alertes budget après ajout produit : implémenté
- Taille réelle foyer : récupérée via HouseholdService

---

## Critères de Validation

**Test de la Mère Camerounaise** :  
"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"

Si NON → simplifier ou repenser UX.

---

## Workflow de Développement

1. **Branch** : Créer `task/1.3.2-description` depuis `main`
2. **Code** : Développer en suivant guidelines
3. **Test** : Exécuter format, analyze, test
4. **Review** : Auto-review avec cette checklist
5. **Commit** : Message clair, atomique
6. **Push** : Vers branche feature
7. **PR** : Créer PR avec description détaillée + checklist tests
8. **Merge** : Après validation tests + review

---

## Exemples

### ✅ Bon Commit
```
feat(alerts): implement alert state persistence

- Added migration 0012 for alert_states table
- Created AlertState model with toMap/fromMap
- Implemented AlertStateRepository
- Integrated with AlertService
- Added 5 unit tests

Task: 1.3.2
Tests: ✅ F2P, ✅ P2F (flutter test passes)
```

### ❌ Mauvais Commit
```
fixed stuff
```

---

## Checklist Pré-Commit

- [ ] `flutter format --set-exit-if-changed lib test` ✅
- [ ] `flutter analyze` sans erreur ✅
- [ ] `flutter test` passe à 100% ✅
- [ ] Pas de `print()` oubliés en code prod
- [ ] Tous textes UI via `l10n`
- [ ] Semantic labels ajoutés (accessibilité)
- [ ] Tests écrits pour nouvelle logique
- [ ] Documentation (`///`) pour APIs publiques
- [ ] Message commit clair et descriptif

---

**Résumé** : Code propre, tests verts, commits clairs, UX intuitive, respect strict des guidelines.
