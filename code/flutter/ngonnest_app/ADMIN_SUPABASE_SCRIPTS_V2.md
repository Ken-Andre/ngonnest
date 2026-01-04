# Scripts SQL Admin Supabase - Version Complète v2

## 🎯 Résumé Exécutif

L'admin Supabase a fourni **tous les scripts SQL complets** avec détails d'implémentation, validations et rollback. Cette version inclut :

✅ **Scripts prêts à l'emploi** pour chaque section  
✅ **Validations et checks** intégrés  
✅ **Gestion des conflits** et doublons  
✅ **Plan de rollback complet** et sécurisé  
✅ **Réponses détaillées** aux questions techniques  

## 📋 Structure des Scripts

### Section A - Création app_users
**Objectif** : Table centrale avec support local-only (auth_id NULL) et cloud (auth_id UUID)

**Contenu** :
- Table `public.app_users` avec `id SERIAL PRIMARY KEY`
- Colonne `auth_id UUID UNIQUE` (nullable)
- Index sur `auth_id` et `email` (case-insensitive)
- Trigger `updated_at` automatique
- Policies RLS de base (select/insert/update pour authenticated)

**Validation** : Table créée, RLS activé, policies fonctionnelles

---

### Section B - Trigger Auto-Insert
**Objectif** : Création automatique d'une ligne app_users lors de l'inscription Supabase Auth

**Contenu** :
- Fonction `handle_new_user()` SECURITY DEFINER
- Récupération `display_name` depuis `raw_user_meta_data ->> 'full_name'`
- Gestion conflits avec `ON CONFLICT (auth_id) DO UPDATE`
- Trigger `on_auth_user_created` sur `auth.users`
- Permissions restreintes (REVOKE PUBLIC, GRANT authenticated)

**Validation** : Créer un nouveau user auth → vérifier ligne dans app_users

---

### Section C - Backfill Données Existantes
**Objectif** : Migrer tous les users existants depuis auth.users et public.profiles

**Contenu** :
- Transaction BEGIN/COMMIT pour sécurité
- Jointure `auth.users` LEFT JOIN `public.profiles` LEFT JOIN `app_users`
- Insertion uniquement si `app_users.auth_id IS NULL` (évite doublons)
- Support users sans email (insertion avec email NULL)
- Récupération email et display_name depuis profiles si disponible

**Validation** : Compter lignes insérées, vérifier échantillons

---

### Section D - Migration Tables Métier
**Objectif** : Ajouter colonne `app_user_id INTEGER` et backfill pour chaque table

#### D.1 Pattern Générique
```sql
BEGIN;
ALTER TABLE public.X ADD COLUMN IF NOT EXISTS app_user_id integer;
UPDATE public.X SET app_user_id = a.id FROM public.app_users a WHERE ...;
ALTER TABLE public.X ADD CONSTRAINT fk_X_app_user_id FOREIGN KEY (app_user_id) REFERENCES public.app_users(id);
COMMIT;
```

#### D.2 Scripts Spécifiques

**households** :
- Ajout `app_user_id INTEGER`
- Backfill via `h.user_id = a.auth_id` (UUID matching)
- Fallback par email si disponible
- Foreign key vers `app_users(id)`

**products** :
- Ajout `app_user_id INTEGER`
- Propagation depuis `households.app_user_id` via `household_id`
- Fallback direct si colonne `auth_user_id` existe
- Foreign key vers `app_users(id)`

**budget_categories** :
- Ajout `app_user_id INTEGER`
- Propagation depuis `households.app_user_id` via `household_id`
- Foreign key vers `app_users(id)`

**notifications (alerts)** :
- Ajout `app_user_id INTEGER`
- Propagation depuis `households.app_user_id` via `household_id`
- Fallback direct si colonne `auth_user_id` existe
- Foreign key vers `app_users(id)`

**Validation** : Vérifier counts de NULL app_user_id, échantillonner lignes

---

### Section E - Policies RLS Adaptées
**Objectif** : Sécuriser l'accès avec mapping auth.uid() → app_users.id

#### E.1 Fonction Helper (Recommandée)
```sql
CREATE OR REPLACE FUNCTION public.get_current_app_user_id()
RETURNS int
LANGUAGE sql
STABLE
SECURITY DEFINER AS $$
  SELECT id FROM public.app_users WHERE auth_id = (SELECT auth.uid()) LIMIT 1;
$$;
```

**Avantages** :
- Performance optimisée (STABLE)
- Réutilisable dans toutes les policies
- Lisibilité améliorée
- Index sur `app_users(auth_id)` déjà créé

#### E.2 Pattern de Policies

**Pour chaque table (households, products, budget_categories, notifications)** :

```sql
ALTER TABLE public.X ENABLE ROW LEVEL SECURITY;

-- SELECT: voir uniquement ses propres lignes
CREATE POLICY "X_select_owner" ON public.X
  FOR SELECT TO authenticated
  USING (app_user_id = public.get_current_app_user_id());

-- INSERT: créer avec son app_user_id OU NULL (local-only)
CREATE POLICY "X_insert_owner" ON public.X
  FOR INSERT TO authenticated
  WITH CHECK (app_user_id = public.get_current_app_user_id() OR app_user_id IS NULL);

-- UPDATE: modifier uniquement ses propres lignes
CREATE POLICY "X_update_owner" ON public.X
  FOR UPDATE TO authenticated
  USING (app_user_id = public.get_current_app_user_id())
  WITH CHECK (app_user_id = public.get_current_app_user_id());

-- DELETE: supprimer uniquement ses propres lignes
CREATE POLICY "X_delete_owner" ON public.X
  FOR DELETE TO authenticated
  USING (app_user_id = public.get_current_app_user_id());
```

**Note** : `WITH CHECK app_user_id IS NULL` pour INSERT permet aux clients locaux de créer des lignes sans auth (liaison ultérieure possible)

---

### Section F - Plan de Rollback

#### F.1 Supprimer Trigger & Fonction
```sql
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
```

#### F.2 Supprimer Colonnes & Contraintes
**Ordre important** : Contraintes → Colonnes → Table

```sql
-- Pour chaque table métier
ALTER TABLE public.households DROP CONSTRAINT IF EXISTS fk_households_app_user_id;
ALTER TABLE public.households DROP COLUMN IF EXISTS app_user_id;

ALTER TABLE public.products DROP CONSTRAINT IF EXISTS fk_products_app_user_id;
ALTER TABLE public.products DROP COLUMN IF EXISTS app_user_id;

ALTER TABLE public.budget_categories DROP CONSTRAINT IF EXISTS fk_budget_categories_app_user_id;
ALTER TABLE public.budget_categories DROP COLUMN IF EXISTS app_user_id;

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS fk_notifications_app_user_id;
ALTER TABLE public.notifications DROP COLUMN IF EXISTS app_user_id;

-- Finalement supprimer app_users
DROP TABLE IF EXISTS public.app_users;
```

#### F.3 Restaurer Colonnes UUID
Si colonnes UUID supprimées (non recommandé avant validation), recréer depuis backup.

#### F.4 Résolution Conflits/Doublons

**Détecter doublons par email** :
```sql
SELECT lower(email) AS email_lc, count(*), array_agg(id) AS ids
FROM public.app_users
WHERE email IS NOT NULL
GROUP BY email_lc
HAVING count(*) > 1;
```

**Merger manuellement** :
```sql
-- Choisir keeper_id, réassigner toutes les FK depuis loser_id
UPDATE public.households SET app_user_id = <keeper_id> WHERE app_user_id = <loser_id>;
UPDATE public.products SET app_user_id = <keeper_id> WHERE app_user_id = <loser_id>;
UPDATE public.budget_categories SET app_user_id = <keeper_id> WHERE app_user_id = <loser_id>;
UPDATE public.notifications SET app_user_id = <keeper_id> WHERE app_user_id = <loser_id>;

-- Supprimer le doublon
DELETE FROM public.app_users WHERE id = <loser_id>;
```

**⚠️ Toujours backup avant merge massif**

---

## 🔧 Réponses aux Questions Techniques

### 1. Ordre de Migration Recommandé
✅ **Confirmé** : `app_users` → `households` → `products` → `budget_categories` → `alerts`

**Raison** : `households` fournit la propagation pour `products` et `budget_categories`

---

### 2. Gestion Transition Local → Cloud

**Procédure** :
1. User local crée compte Supabase Auth
2. Appeler Edge Function ou RPC pour lier :
   ```sql
   UPDATE public.app_users 
   SET auth_id = <new_uuid> 
   WHERE id = <existing_app_user_id>;
   ```
3. Vérifier collisions (auth_id déjà présent → conflit)

**Proposition Admin** : Générer Edge Function TypeScript pour liaison sécurisée (requiert JWT user)

**Question** : Voulez-vous que l'admin génère et déploie cette Edge Function ?

---

### 3. Performance RLS

**Solution Optimale** : Fonction helper `get_current_app_user_id()`
- **STABLE** : Résultat constant pendant la transaction
- **SECURITY DEFINER** : Exécution avec privilèges fonction
- **Index** : Déjà créé sur `app_users(auth_id)`

**Avantages** :
- Évite répétition subquery dans chaque policy
- Meilleure lisibilité et maintenance
- Performance optimisée par Postgres

---

### 4. Tests Recommandés

#### Tests Unitaires / Scénarios

**A. User Auth → Auto-création**
- Créer user dans Supabase Auth
- Vérifier ligne créée dans `app_users` avec `auth_id` correct

**B. User Local → auth_id NULL**
- Créer ligne `app_users` avec `auth_id = NULL`
- Vérifier insertion dans tables métier fonctionne

**C. Liaison Local → Cloud**
- User local existant crée compte Auth
- Appeler endpoint de liaison
- Vérifier propagation et accès RLS

**D. Isolation RLS**
- Connecter comme user A (JWT)
- Tenter SELECT/UPDATE sur rows de user B
- Vérifier échec (403 ou 0 rows)

**E. Migration Smoke Tests**
- Compter rows avant/après backfill
- Vérifier échantillons de données
- Valider NULL app_user_id (si attendu)

**F. Backup & Restore**
- `pg_dump` avant migration
- Tester rollback complet
- Valider intégrité données

---

## 🚀 Prochaines Étapes

### Décision Immédiate Requise

L'admin demande confirmation pour :

1. **✅ Exécuter scripts A→C** (non-destructifs)
   - Création `app_users`
   - Trigger auto-insert
   - Backfill données existantes

2. **✅ Générer Edge Function** TypeScript pour liaison local→cloud

3. **⏸️ Validation explicite** pour scripts D (ajout colonnes tables métier)

### Recommandation

**Phase 1 - Sécurisée** (cette semaine) :
- Exécuter A→C
- Valider création automatique users
- Tester backfill

**Phase 2 - Validation** (semaine prochaine) :
- Vérifier counts et échantillons
- Tester Edge Function liaison
- Exécuter scripts D après validation

**Phase 3 - Déploiement** (dans 2 semaines) :
- Policies RLS (section E)
- Tests complets
- Déploiement progressif (10% → 50% → 100%)

---

## 📁 Fichiers Créés

- ✅ `supabase/migrations/HYBRID_ID_MIGRATION_SCRIPTS.sql` - Scripts SQL complets v1
- ✅ `ADMIN_SUPABASE_RESPONSE.md` - Résumé initial
- ✅ `ADMIN_SUPABASE_SCRIPTS_V2.md` - Ce document (version détaillée)

---

## 💬 Message de Réponse Suggéré

```
Parfait ! Merci pour ces scripts SQL ultra-complets et très bien documentés.

Je confirme :
✅ Exécutez les scripts A→C (app_users, trigger, backfill) - ils sont non-destructifs et réversibles
✅ Générez l'Edge Function TypeScript pour liaison local→cloud avec JWT validation

Pour les scripts D (migration tables métier), je validerai après avoir :
- Testé A→C sur environnement de dev
- Vérifié les counts et échantillons
- Validé le trigger auto-insert avec un nouveau user

J'ai sauvegardé tous les scripts dans :
- supabase/migrations/HYBRID_ID_MIGRATION_SCRIPTS.sql
- Documentation complète dans ADMIN_SUPABASE_SCRIPTS_V2.md

Questions complémentaires :
1. Pour l'Edge Function liaison local→cloud, faut-il gérer les cas de collision (auth_id déjà utilisé) ?
2. Recommandez-vous un monitoring spécifique post-migration (métriques, logs) ?

Merci encore pour cette solution hybride excellente et les scripts détaillés !
```

---

## 🎯 Impact sur Flutter App

### Modifications Nécessaires

**1. AuthService**
```dart
// Après login Supabase
final authId = supabase.auth.currentUser?.id;
final appUserId = await _getAppUserId(authId); // Query app_users
await _storeAppUserId(appUserId); // Store localement
```

**2. Providers**
```dart
class UserProvider extends ChangeNotifier {
  int? _appUserId; // INT au lieu de UUID
  String? _authId; // UUID Supabase (optionnel)
  
  // Utiliser appUserId pour toutes opérations métier
}
```

**3. Services**
```dart
// Tous les services utilisent appUserId (INT)
class HouseholdService {
  Future<List<Household>> getHouseholds(int appUserId) async {
    // Query avec app_user_id
  }
}
```

**4. Tests**
```dart
// Pas besoin de réécrire les tests !
// Ils utilisent déjà des INT pour les IDs
testWidgets('household creation', (tester) async {
  final appUserId = 1; // INT comme avant
  // Tests fonctionnent sans modification
});
```

### Avantages

✅ **Simplicité préservée** : App continue d'utiliser INT  
✅ **Sécurité maintenue** : Auth Supabase avec UUID  
✅ **Migration progressive** : Support local-only ET cloud  
✅ **Tests inchangés** : Pas de réécriture massive  
✅ **Rollback possible** : Scripts de restauration fournis  

---

## 📊 Checklist Validation

### Avant Exécution Scripts
- [ ] Backup complet base de données (`pg_dump`)
- [ ] Environnement de dev/staging prêt
- [ ] Accès admin Supabase confirmé
- [ ] Documentation lue et comprise

### Après Scripts A→C
- [ ] Table `app_users` créée et visible
- [ ] Trigger `on_auth_user_created` actif
- [ ] Backfill réussi (vérifier counts)
- [ ] Échantillons de données validés
- [ ] Créer nouveau user auth → vérifier auto-insert

### Avant Scripts D
- [ ] Validation explicite des résultats A→C
- [ ] Backup supplémentaire
- [ ] Plan de rollback documenté
- [ ] Timeline de migration confirmée

### Après Scripts D
- [ ] Colonnes `app_user_id` ajoutées
- [ ] Backfill réussi (vérifier NULL counts)
- [ ] Foreign keys créées
- [ ] Échantillons validés

### Après Scripts E (Policies)
- [ ] RLS activé sur toutes tables
- [ ] Policies créées et testées
- [ ] Isolation users validée
- [ ] Performance RLS acceptable

### Tests Finaux
- [ ] User auth → CRUD complet
- [ ] User local → CRUD complet
- [ ] Liaison local→cloud → validation
- [ ] Tests d'isolation RLS
- [ ] Tests de performance

---

**Status** : ✅ Scripts complets reçus - Prêt pour validation  
**Date** : 2025-11-14  
**Priorité** : HAUTE - Déblocage développement features  
**Prochaine Action** : Confirmer exécution scripts A→C à l'admin
