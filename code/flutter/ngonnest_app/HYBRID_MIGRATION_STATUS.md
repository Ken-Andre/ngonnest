# Migration Hybride INT+UUID - Status

## ✅ FAIT (Supabase)

1. **Table app_users créée** - Mapping UUID ↔ INT
2. **Trigger auto-insert actif** - Création automatique lors signup
3. **Backfill exécuté** - Users existants migrés
4. **Edge Functions déployées** :
   - `link-local-to-cloud` : Lier user local à auth cloud
   - `merge-local-to-cloud` : Fusionner données local→cloud

## ✅ FAIT (Flutter)

1. **AuthService modifié** - Récupère `app_user_id` (INT) après login
2. **Méthode `getAppUserId()`** - Accessible pour tous les services

## ❌ À FAIRE (Flutter)

### 1. Tester AuthService
```bash
flutter test test/services/auth_service_test.dart
```

### 2. Modifier les Services pour utiliser app_user_id
- `FoyerRepository` : Utiliser `app_user_id` au lieu de UUID
- `InventoryRepository` : Utiliser `app_user_id`
- `BudgetService` : Utiliser `app_user_id`
- `SyncService` : Utiliser `app_user_id`

### 3. Tester l'app complète
- Signup → Vérifier `app_user_id` stocké
- Login → Vérifier `app_user_id` récupéré
- CRUD foyers → Vérifier utilisation INT
- Sync cloud → Vérifier fonctionnement

## 🎯 PRIORITÉ IMMÉDIATE

**Modifier `FoyerRepository`** pour utiliser `app_user_id` au lieu de UUID.

C'est le service principal qui bloque tout le reste.
