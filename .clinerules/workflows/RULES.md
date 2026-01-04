# RULES.md - Règles de Développement NgonNest

## Règles Fondamentales

### 1. Critère de Validation Ultime
**TOUTE** fonctionnalité doit passer le test : 
> "Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"

Si la réponse est NON → simplifier ou reporter.

### 2. Offline First - Toujours
- L'app DOIT fonctionner à 100% hors ligne pour les fonctionnalités de base
- SQLite = source de vérité
- Sync cloud = optionnelle avec consentement explicite
- Pas de dépendance réseau pour le MVP

### 3. Performance Camerounaise
- Taille app < 25 Mo
- Compatible Android 8.0+ (75% du marché camerounais)
- Fonctionne sur 2 Go RAM minimum
- Temps de chargement < 2 secondes
- Consommation batterie < 1%/jour

## Règles de Code

### 4. Architecture Obligatoire
```
MVVM + Repository Pattern
├── Models (données pures)
├── Repositories (accès données)
├── Services (logique métier)
├── Providers (état UI)
└── Screens (interface)
```

### 5. Gestion d'Erreur Stricte
- TOUS les try/catch utilisent `ErrorLoggerService`
- Messages d'erreur conviviaux pour l'utilisateur
- Logs techniques détaillés pour debug
- Pas de crash silencieux

### 6. Base de Données
- SQLite avec cryptage AES-256
- Migrations versionnées
- Indexes sur FK et champs recherche
- Backup/restore automatique

## Règles UI/UX

### 7. Design System Strict
- Utilise UNIQUEMENT `AppTheme`
- Couleurs cohérentes avec le branding
- Contraste ≥ 4.5:1 (accessibilité)
- Taille police ≥ 16px

### 8. Navigation Intuitive
- Maximum 3 clics pour action critique
- Breadcrumbs clairs
- Retour arrière prévisible
- Pas de dead-ends

### 9. États UI Obligatoires
- Loading : `CupertinoActivityIndicator`
- Error : `SnackBar` avec message convivial
- Empty : Illustration + call-to-action
- Success : Feedback visuel immédiat

## Règles Fonctionnelles

### 10. Onboarding Express
- Profil foyer en < 2 minutes
- Sliders/dropdowns (pas de saisie libre)
- Illustrations pour estimation tailles
- Validation temps réel

### 11. Inventaire Intelligent
- Auto-suggestions basées profil
- Catégorisation automatique
- Scan optionnel (pas obligatoire)
- Modification en 1 clic

### 12. Rappels Prévisibles
- Notifications 3-5 jours avant rupture
- Sync calendrier natif
- Liste courses exportable
- Snooze intelligent

## Règles Techniques

### 13. Internationalisation Native
- FR/EN/ES minimum
- Pas de texte hardcodé
- Format dates/prix localisé
- Extension langues camerounaises

### 14. Tests Non-Négociables
- Couverture ≥ 80% services/repositories
- Tests widgets écrans critiques
- Mocks pour dépendances externes
- Golden tests UI principales

### 15. Sécurité & Privacy
- Données sensibles cryptées
- Permissions justifiées
- Consentement explicite sync
- Pas de tracking sans accord

## Règles Métier

### 16. Recommandations Expertes
- Basées sur profil foyer réel
- Validées par hygiénistes
- Modifiables par utilisateur
- Apprentissage progressif

### 17. Budget Réaliste
- Prix en FCFA (Cameroun)[mais en Euro en background]
- Ajustement inflation annuel
- Conseils économies simples
- Pas de gestion finances directe

### 18. Gamification Subtile
- Encouragements positifs
- Badges progression
- Pas de compétition
- Focus utilité vs fun

## Règles de Qualité

### 19. Code Review Checklist
- [ ] Passe le test "mère de 52 ans"
- [ ] Fonctionne offline
- [ ] Performance OK sur 2Go RAM
- [ ] Gestion erreur complète
- [ ] Tests unitaires présents
- [ ] Documentation à jour

### 20. Commit Standards
- Format : `type(scope): description`
- Types : feat, fix, docs, style, refactor, test
- Description ≤ 72 caractères
- Corps explicatif si nécessaire

## Règles d'Évolution

### 21. MVP First
- Fonctionnalités essentielles uniquement
- Pas de feature creep
- Validation terrain obligatoire
- Itération rapide

### 22. Scalabilité Préparée
- Architecture extensible
- Points d'extension documentés
- Migration path planifiée
- Backward compatibility

### 23. Feedback Continu
- Tests utilisateurs hebdomadaires
- Métriques usage trackées
- A/B tests fonctionnalités
- Amélioration continue

## Violations & Sanctions

### Violations Mineures (Warning)
- Texte hardcodé
- Pas de gestion erreur
- Performance dégradée
- Tests manquants

### Violations Majeures (Revert)
- Crash en production
- Fuite données sensibles
- Régression fonctionnelle
- Breaking change non documenté

### Violations Critiques (Rollback)
- Sécurité compromise
- Perte données utilisateur
- App inutilisable
- Non-conformité légale

## Exceptions Autorisées

### Cas d'Exception
- Contraintes techniques insurmontables
- Délais critiques validés
- Proof of concept temporaire
- Debug en développement

### Processus Exception
1. Documentation justification
2. Validation lead technique
3. Plan de résolution
4. Timeline correction

---

**Rappel** : Ces règles garantissent que NgonNest reste fidèle à sa vision : une app simple, performante et adaptée aux réalités camerounaises.

*"Simplicité, Performance, Utilité - Dans cet ordre."*
