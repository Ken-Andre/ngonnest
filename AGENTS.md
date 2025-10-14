# AGENTS.md

## Portée
Ces consignes s’appliquent à tout le dépôt `ngonnest`.
Tu les suis à la lettre dès que tu touches un fichier.

## Coups de pouce avant chaque commit
- `flutter format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- (si des mocks changent) `dart run build_runner build --delete-conflicting-outputs`

## Style & commits
- Code Dart/Flutter, null‑safety obligatoire.
- Fichiers en `snake_case` ; classes en `PascalCase` ; variables en `camelCase`.
- Commentaires‑doc (`///`) pour les APIs publiques.
- Textes UI via i18n (`l10n`), jamais en dur dans le code.
- Logs: utiliser `ErrorLoggerService`/`console_logger` (éviter `print` hors debug).
- Un commit = une idée. Sujet ≤ 72 caractères, présent, sans point final.
- Branches: `feature/...`, `fix/...`, `chore/...` → PR vers `main` avec tests verts.

## Repo rapide
- App Flutter: `code/flutter/ngonnest_app/`
- Bot Telegram: `code/telegram_bot/`
- Docs produit/tech: `docs/`

## Backlog actuel (MVP)
1. **Sync offline‑first** – remplacer le placeholder dans `lib/services/sync_service.dart`:
   - file d’opérations locales, reprise/réessai exponentiel, « local wins », résolution de conflits simple (horodatage), tests unitaires/intégration.
2. **Permissions calendrier** – nettoyer `_requestPermissions` dans `lib/services/calendar_sync_service.dart`:
   - flux Android 13+, iOS, Web/Desktop (gracieux), messages UX et retours d’erreur, tests.
3. **Feedback & bugs** – finaliser les actions dans `lib/screens/settings_screen.dart`:
   - branchement HTTP/Telegram, gestion erreurs réseau, confirmation utilisateur, tests.
4. **Suggestions produits** – homogénéiser types et entrées:
   - corriger l’ID foyer (string⇄int) dans `ProductSuggestionService`, normaliser catégories/units, tests.
5. **Price & inflation** – enrichir `PriceService` et `config/cameroon_prices.dart`:
   - prix moyens FCFA, ajustement annuel, devise locale, fallback.
6. **Onboarding profil foyer** – compléter la collecte (pièces, tailles) dans `onboarding_screen.dart` et alimentation des services.
7. **Logs & erreurs** – remplacer les `print` persistants par `ErrorLoggerService`/`console_logger`, niveaux de sévérité, métadonnées.
8. **Export/Import** – validation schéma JSON et tests de non‑régression.
9. **A11y & i18n** – couvrir les nouveaux écrans (libellés, contrastes, navigation clavier/lecteur d’écran), tests existants à étendre.

### Résolus (à retirer du backlog historique)
- `'/edit-objet'` et écran associé: présent (`main.dart`, `edit_product_screen.dart`).
- Alertes budget après ajout/mise à jour: appel en place (`AddProductScreen`, `EditProductScreen`).
- Taille réelle du foyer: récupérée via `HouseholdService` dans `AddProductScreen`.
- Fichier parasite `settings_screen .dart.txt`: non présent dans la base actuelle.

## Définitions de prêt à livrer (DoD)
- Formatage OK, analyse statique sans erreur, tests verts.
- Strings localisées, accessibilité de base validée.
- Offline‑first: pas de crash hors‑ligne, sync non bloquante.
- Logs d’erreur avec contexte, sans données sensibles.
- Documentation mise à jour (ce fichier + `rules.md` si pertinent).
