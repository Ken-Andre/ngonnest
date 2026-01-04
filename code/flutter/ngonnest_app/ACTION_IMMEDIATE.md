# ACTION IMMÉDIATE - Débloquer l'Auth et le Sync

## 🎯 Objectif
Faire fonctionner l'authentification et le sync avec la solution hybride INT+UUID.

## ✅ DÉJÀ FAIT

### Côté Supabase (par l'admin)
- Table `app_users` créée et fonctionnelle
- Trigger auto-insert actif
- Backfill des users existants
- Edge Functions déployées

### Côté Flutter (par nous)
- `AuthService.getAppUserId()` implémenté
- Récupération automatique de `app_user_id` après login

## 🚀 PROCHAINES ÉTAPES (dans l'ordre)

### 1. Tester que AuthService fonctionne ✅
```bash
cd code/flutter/ngonnest_app
flutter test test/services/auth_service_test.dart
```

**Si ça passe** : AuthService est OK
**Si ça casse** : Fixer les tests

### 2. Vérifier que l'app compile
```bash
flutter analyze
```

### 3. Tester l'app en mode dev
```bash
flutter run
```

**Test manuel** :
1. Créer un compte (signup)
2. Vérifier dans les logs : "app_user_id fetched and stored: X"
3. Se déconnecter
4. Se reconnecter
5. Vérifier que `app_user_id` est récupéré

### 4. Si tout fonctionne jusqu'ici
Alors l'authentification est **RÉPARÉE** ✅

## 📝 Notes Importantes

### L'app utilise DÉJÀ des INT localement
- Les modèles (`Foyer`, `Objet`, etc.) utilisent `int?` pour les IDs
- La base SQLite locale utilise des INT auto-incrémentés
- **Aucun changement de code métier nécessaire**

### Ce qui change
- `AuthService` récupère maintenant `app_user_id` (INT) en plus de `auth_id` (UUID)
- Les services cloud utiliseront `app_user_id` pour les requêtes Supabase
- **C'est tout !**

### Pourquoi c'est simple
La solution hybride fait exactement ce qu'on voulait :
- **Local** : Continue d'utiliser INT (rien ne change)
- **Cloud** : Utilise `app_user_id` (INT) au lieu de UUID
- **Mapping** : Géré automatiquement par Supabase

## ⚠️ Ce qu'il NE FAUT PAS faire

- ❌ Réécrire tous les modèles
- ❌ Changer tous les services
- ❌ Modifier la base SQLite locale
- ❌ Créer 50 documents de plus

## ✅ Ce qu'il FAUT faire

1. Tester que l'auth fonctionne
2. Vérifier que `app_user_id` est bien récupéré
3. C'est tout pour l'instant

## 🎯 Résultat Attendu

Après ces étapes :
- ✅ Signup fonctionne
- ✅ Login fonctionne
- ✅ `app_user_id` est stocké localement
- ✅ L'app peut utiliser cet ID pour le sync

**Ensuite** on pourra s'occuper du sync, mais **une chose à la fois**.
