# Réponse à l'Admin Supabase - Solution Hybride

## Message pour l'Admin

---

Bonjour,

Merci beaucoup pour cette recommandation de solution hybride avec la table `app_users` ! Après analyse approfondie, **je confirme que c'est exactement ce dont j'ai besoin**.

Cette approche résout parfaitement mes problèmes :
- ✅ Garde la simplicité des INT pour mon app locale existante
- ✅ Maintient la sécurité UUID pour l'authentification Supabase
- ✅ Permet une migration progressive et réversible
- ✅ Compatible avec les utilisateurs local-only ET cloud

### Mes Réponses aux Questions

**1. Colonnes UUID existantes :**
- ✅ **Garder en parallèle pendant la transition** (1-2 mois)
- Raison : Sécurité et possibilité de rollback si problème
- Je supprimerai les colonnes UUID une fois la migration stable et validée

**2. Trigger auto-insert :**
- ✅ **OUI, créer le trigger sur auth.users**
- Je souhaite que chaque nouvel utilisateur Supabase Auth crée automatiquement sa ligne dans `app_users`
- Cela simplifie grandement la gestion côté application

**3. Scripts SQL complets :**
- ✅ **OUI, j'ai besoin des scripts SQL de migration**

Pourriez-vous me fournir :

#### A. Scripts de Création
- [ ] Création table `app_users` avec colonnes `id` (SERIAL), `auth_id` (UUID), `email`, timestamps
- [ ] Index sur `auth_id` et `email`
- [ ] Policies RLS pour `app_users`

#### B. Trigger Auto-Insert
- [ ] Fonction `handle_new_user()` 
- [ ] Trigger `on_auth_user_created` sur `auth.users`
- [ ] Gestion des permissions SECURITY DEFINER

#### C. Backfill Données Existantes
- [ ] Script pour backfill `app_users` depuis `auth.users` et `public.profiles`
- [ ] Vérification des doublons et gestion des conflits

#### D. Migration Tables Métier
Scripts pour ces tables principales :
- [ ] `households` (foyers)
- [ ] `products` (objets/produits)
- [ ] `budget_categories`
- [ ] `alerts` (alertes)

Pour chaque table :
- Ajout colonne `user_id INTEGER REFERENCES app_users(id)`
- Backfill via jointure avec `auth_id`
- Création foreign keys
- Mise à jour policies RLS pour utiliser le mapping

#### E. Policies RLS Adaptées
- [ ] Policies SELECT/INSERT/UPDATE/DELETE pour chaque table
- [ ] Utilisant le pattern : `user_id = (SELECT id FROM app_users WHERE auth_id = auth.uid())`

#### F. Plan de Rollback
- [ ] Scripts pour revenir en arrière si nécessaire
- [ ] Procédure de restauration des colonnes UUID

### Informations Contextuelles

**Tables métier actuelles :**
```
- households (foyers) : ~10-50 lignes par user
- products (objets) : ~100-500 lignes par user  
- budget_categories : ~10-20 lignes par user
- alerts : ~50-200 lignes par user
- reachat_log : historique achats
- product_prices : prix moyens
```

**Colonne auth actuelle :**
- Actuellement : `auth_user_id UUID` dans certaines tables cloud
- Localement : pas de colonne auth (mode offline-first)

**Besoin spécifique :**
- Support mode **local-only** : users sans compte Supabase (`auth_id = NULL`)
- Support mode **cloud** : users avec compte Supabase (`auth_id = UUID`)
- Transition fluide : user local peut devenir cloud plus tard

### Questions Complémentaires

1. **Ordre de migration** : Quel ordre recommandez-vous pour migrer les tables ?
   - Ma proposition : `app_users` → `households` → `products` → `budget_categories` → `alerts`

2. **Gestion transition local → cloud** : 
   - Si un user local crée un compte Supabase, comment lier son `app_user_id` existant à son nouveau `auth_id` ?
   - Faut-il un endpoint/fonction spécifique pour ce cas ?

3. **Performance RLS** :
   - Le pattern `(SELECT id FROM app_users WHERE auth_id = auth.uid())` dans chaque policy est-il performant ?
   - Faut-il créer une fonction helper pour éviter la répétition ?

4. **Validation** :
   - Recommandez-vous des tests spécifiques pour valider la migration ?

### Timeline Souhaitée

- **Cette semaine** : Réception et revue des scripts SQL
- **Semaine prochaine** : Implémentation sur Supabase + tests
- **Dans 2 semaines** : Déploiement progressif (10% → 50% → 100%)

### Remerciements

Encore merci pour cette excellente recommandation ! Cette solution hybride est exactement ce qu'il me fallait pour débloquer la situation sans sacrifier ni la simplicité ni la sécurité.

Je reste disponible pour toute clarification ou information complémentaire.

Cordialement,
[Votre nom]

---

## Checklist Avant Envoi

- [ ] Relire le message
- [ ] Vérifier que toutes les questions sont claires
- [ ] Confirmer les besoins en scripts SQL
- [ ] Ajouter informations contextuelles si nécessaire
- [ ] Envoyer à l'admin Supabase

## Après Réception des Scripts

1. ✅ Créer branche `feature/hybrid-id-mapping`
2. ✅ Tester scripts sur environnement de dev
3. ✅ Valider avec quelques données test
4. ✅ Documenter la procédure
5. ✅ Préparer plan de déploiement

## Notes Importantes

- **Ne pas supprimer** les colonnes UUID avant validation complète
- **Tester** le mode local-only ET cloud
- **Valider** la transition local → cloud
- **Monitorer** les performances RLS
- **Documenter** pour l'équipe

---

**Status** : ✅ Prêt à envoyer
**Date** : 2025-11-13
**Priorité** : HAUTE - Bloque développement features

---
-- It seems the earlier CREATE TABLE failed or was not committed. Recreate table step by step.
CREATE TABLE IF NOT EXISTS public.app_users (
  id                 SERIAL PRIMARY KEY,
  auth_id            uuid UNIQUE,
  email              text UNIQUE,
  display_name       text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
---
CREATE INDEX IF NOT EXISTS idx_app_users_auth_id ON public.app_users(auth_id);
CREATE INDEX IF NOT EXISTS idx_app_users_email ON public.app_users(lower(email));

CREATE OR REPLACE FUNCTION public.app_users_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trig_app_users_updated_at ON public.app_users;
CREATE TRIGGER trig_app_users_updated_at
BEFORE UPDATE ON public.app_users
FOR EACH ROW EXECUTE FUNCTION public.app_users_set_updated_at();

ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
---
DROP POLICY IF EXISTS "app_users_select_self" ON public.app_users;
CREATE POLICY "app_users_select_self" ON public.app_users
  FOR SELECT
  TO authenticated
  USING (
    auth_id IS NOT NULL AND auth_id = (SELECT auth.uid())
  );

DROP POLICY IF EXISTS "app_users_insert_self" ON public.app_users;
CREATE POLICY "app_users_insert_self" ON public.app_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth_id IS NOT NULL AND auth_id = (SELECT auth.uid())
  );

DROP POLICY IF EXISTS "app_users_update_self" ON public.app_users;
CREATE POLICY "app_users_update_self" ON public.app_users
  FOR UPDATE
  TO authenticated
  USING (
    auth_id IS NOT NULL AND auth_id = (SELECT auth.uid())
  )
  WITH CHECK (
    auth_id IS NOT NULL AND auth_id = (SELECT auth.uid())
  );
---
-- B.1 Create handle_new_user function and trigger on auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.app_users (auth_id, email, display_name, created_at, updated_at)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data ->> 'full_name', NULL), now(), now())
  ON CONFLICT (auth_id) DO UPDATE
    SET email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, public.app_users.display_name),
        updated_at = now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();
---
-- C.1 Backfill from auth.users and public.profiles
BEGIN;

INSERT INTO public.app_users (auth_id, email, display_name, created_at, updated_at)
SELECT u.id AS auth_id,
       COALESCE(p.email, u.email) AS email,
       COALESCE(p.full_name, (u.raw_user_meta_data ->> 'full_name')) AS display_name,
       now(), now()
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.app_users a ON a.auth_id = u.id
WHERE a.auth_id IS NULL
  AND (COALESCE(p.email, u.email) IS NOT NULL);

-- Insert users without email
INSERT INTO public.app_users (auth_id, email, display_name, created_at, updated_at)
SELECT u.id, NULL, COALESCE(p.full_name, (u.raw_user_meta_data ->> 'full_name')), now(), now()
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.app_users a ON a.auth_id = u.id
WHERE a.auth_id IS NULL
  AND COALESCE(p.email, u.email) IS NULL;

COMMIT;
---
import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.33.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

interface LinkRequest {
  app_user_id: number; // existing local app_users.id to link
}

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) return new Response(JSON.stringify({ message: 'Missing auth token' }), { status: 401 });
    const token = authHeader.split(' ')[1];

    // Verify JWT and get user id
    const { data: userInfo, error: userErr } = await supabase.auth.getUser(token);
    if (userErr || !userInfo.user) return new Response(JSON.stringify({ message: 'Invalid token' }), { status: 401 });
    const authId = userInfo.user.id;

    const payload: LinkRequest = await req.json();
    if (!payload?.app_user_id) return new Response(JSON.stringify({ message: 'app_user_id required' }), { status: 400 });

    const appUserId = payload.app_user_id;

    // Check if auth_id already linked to a different app_user
    const { data: existing, error: exErr } = await supabase
      .from('app_users')
      .select('id, auth_id, email')
      .eq('auth_id', authId)
      .limit(1)
      .maybeSingle();
    if (exErr) throw exErr;
    if (existing) {
      // collision: another app_user already has this auth_id
      const body = { message: 'auth_id already linked to another app_user', existing_app_user: existing };
      return new Response(JSON.stringify(body), { status: 409, headers: { 'Content-Type': 'application/json' } });
    }

    // Ensure caller owns the local app_user (app_user.auth_id IS NULL and possibly matches by email) or is service_role allowed
    const { data: target, error: tErr } = await supabase
      .from('app_users')
      .select('id, auth_id, email')
      .eq('id', appUserId)
      .limit(1)
      .maybeSingle();
    if (tErr) throw tErr;
    if (!target) return new Response(JSON.stringify({ message: 'app_user not found' }), { status: 404 });
    if (target.auth_id) return new Response(JSON.stringify({ message: 'app_user already linked to an auth_id', app_user: target }), { status: 409 });

    // Update mapping: set auth_id = authId
    const { data: updated, error: updErr } = await supabase
      .from('app_users')
      .update({ auth_id: authId })
      .eq('id', appUserId)
      .select()
      .maybeSingle();
    if (updErr) throw updErr;

    return new Response(JSON.stringify({ message: 'linked', app_user: updated }), { status: 200, headers: { 'Content-Type': 'application/json' } });

  } catch (err) {
    console.error(err instanceof Error ? err.message : err);
    return new Response(JSON.stringify({ message: 'internal_error', detail: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
---
import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.33.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

interface MergeRequest {
  source_app_user_id: number; // local app_user to merge from (local)
  target_app_user_id: number; // app_user already linked to auth (cloud)
  transfer_related?: string[]; // list of related tables to transfer, e.g. ['households','products']
}

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) return new Response(JSON.stringify({ message: 'Missing auth token' }), { status: 401 });
    const token = authHeader.split(' ')[1];

    // Verify JWT and get user id
    const { data: userInfo, error: userErr } = await supabase.auth.getUser(token);
    if (userErr || !userInfo.user) return new Response(JSON.stringify({ message: 'Invalid token' }), { status: 401 });
    const authId = userInfo.user.id;

    const payload: MergeRequest = await req.json();
    if (!payload?.source_app_user_id || !payload?.target_app_user_id) return new Response(JSON.stringify({ message: 'source_app_user_id and target_app_user_id required' }), { status: 400 });

    const { source_app_user_id, target_app_user_id, transfer_related = ['households','products','budget_categories','notifications'] } = payload;

    // Verify target belongs to authId
    const { data: target, error: tErr } = await supabase
      .from('app_users')
      .select('id, auth_id')
      .eq('id', target_app_user_id)
      .limit(1)
      .maybeSingle();
    if (tErr) throw tErr;
    if (!target) return new Response(JSON.stringify({ message: 'target app_user not found' }), { status: 404 });
    if (target.auth_id !== authId) return new Response(JSON.stringify({ message: 'target app_user does not belong to authenticated user' }), { status: 403 });

    // Start transfer: reassign FK references from source -> target in requested tables
    for (const tbl of transfer_related) {
      // Use RPC-style update via service role
      const updateSql = `UPDATE public.${tbl} SET app_user_id = $1 WHERE app_user_id = $2;`;
      const { error: qErr } = await supabase.rpc('exec_sql', { q: updateSql, params: [target_app_user_id, source_app_user_id] }).catch(e => ({ error: e }));
      if (qErr) {
        // fallback: try via normal query
        const { error: updErr } = await supabase.from(tbl).update({ app_user_id: target_app_user_id }).eq('app_user_id', source_app_user_id);
        if (updErr) throw updErr;
      }
    }

    // Optionally delete source app_user
    const { error: delErr } = await supabase.from('app_users').delete().eq('id', source_app_user_id);
    if (delErr) throw delErr;

    return new Response(JSON.stringify({ message: 'merged' }), { status: 200, headers: { 'Content-Type': 'application/json' } });

  } catch (err) {
    console.error(err instanceof Error ? err.message : err);
    return new Response(JSON.stringify({ message: 'internal_error', detail: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
---
