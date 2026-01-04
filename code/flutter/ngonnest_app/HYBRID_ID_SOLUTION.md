# Solution Hybride : INT + UUID (Recommandation Admin Supabase)

## 🎯 Problème Actuel
- Migration UUID complète = 137+ erreurs de tests + complexité énorme
- App locale utilise INT auto-incrémenté (simple, performant)
- Supabase Auth utilise UUID (sécurisé, standard)
- Conflit entre les deux approches

## ✅ Solution Recommandée : Table de Mapping

### Concept
Créer une table `app_users` qui fait le pont entre :
- **UUID** (Supabase Auth) → Authentification et sécurité
- **INT** (App locale) → Toutes les relations métier

### Architecture

```
┌─────────────────┐         ┌──────────────┐         ┌─────────────────┐
│  auth.users     │         │  app_users   │         │  households     │
│  (Supabase)     │────────▶│  (Mapping)   │◀────────│  (Métier)       │
│                 │         │              │         │                 │
│  id: UUID       │         │  id: INT     │         │  user_id: INT   │
│  email: text    │         │  auth_id:    │         │  name: text     │
│                 │         │    UUID      │         │                 │
└─────────────────┘         └──────────────┘         └─────────────────┘
                                    │
                                    │
                            ┌───────▼────────┐
                            │   products     │
                            │   (Métier)     │
                            │                │
                            │  user_id: INT  │
                            │  name: text    │
                            └────────────────┘
```

## 📋 Avantages

### ✅ Pour l'App Locale
- **Garde les INT** : Aucune migration massive nécessaire
- **Performance** : INT plus rapide que UUID pour les jointures
- **Simplicité** : Code existant fonctionne tel quel
- **Tests** : Pas besoin de tout réécrire

### ✅ Pour le Cloud
- **Sécurité** : UUID pour l'authentification (non-prédictible)
- **Standard** : Compatible avec Supabase Auth
- **RLS** : Policies basées sur auth.uid()

### ✅ Migration
- **Incrémentale** : Peut se faire progressivement
- **Réversible** : Facile de revenir en arrière
- **Compatible** : Users locaux ET cloud fonctionnent

## 🗄️ Schéma SQL

### 1. Table app_users (Mapping)

```sql
-- Table de mapping UUID ↔ INT
CREATE TABLE public.app_users (
  id SERIAL PRIMARY KEY,                    -- INT auto-incrémenté
  auth_id UUID UNIQUE,                      -- UUID de auth.users (nullable pour local-only)
  email TEXT,                               -- Email (pour référence)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_app_users_auth_id ON public.app_users(auth_id);
CREATE INDEX idx_app_users_email ON public.app_users(email);

-- RLS
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;

-- Policy : Chaque user voit seulement sa ligne
CREATE POLICY "Users can view own record"
  ON public.app_users
  FOR SELECT
  USING (auth_id = auth.uid());
```

### 2. Trigger Auto-Insert

```sql
-- Fonction pour créer automatiquement app_users lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.app_users (auth_id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (auth_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger sur auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### 3. Mise à Jour Tables Métier

```sql
-- Exemple : households
ALTER TABLE public.households 
  ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES public.app_users(id);

-- Backfill pour données existantes (si auth_user_id existe)
UPDATE public.households h
SET user_id = (
  SELECT au.id 
  FROM public.app_users au 
  WHERE au.auth_id = h.auth_user_id
)
WHERE h.auth_user_id IS NOT NULL;

-- Une fois migré, on peut supprimer l'ancienne colonne
-- ALTER TABLE public.households DROP COLUMN auth_user_id;
```

### 4. RLS avec Mapping

```sql
-- Policy pour households utilisant le mapping
CREATE POLICY "Users can view own households"
  ON public.households
  FOR SELECT
  USING (
    user_id = (
      SELECT id FROM public.app_users 
      WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own households"
  ON public.households
  FOR INSERT
  WITH CHECK (
    user_id = (
      SELECT id FROM public.app_users 
      WHERE auth_id = auth.uid()
    )
  );
```

## 🔄 Plan de Migration

### Phase 1 : Préparation (1 jour)
1. ✅ Créer table `app_users` sur Supabase
2. ✅ Créer trigger auto-insert
3. ✅ Backfill users existants depuis `profiles`

```sql
-- Backfill depuis profiles existants
INSERT INTO public.app_users (auth_id, email)
SELECT id, email FROM auth.users
ON CONFLICT (auth_id) DO NOTHING;
```

### Phase 2 : Migration Tables (2 jours)
1. Ajouter colonne `user_id INT` à chaque table métier
2. Backfill les données existantes
3. Créer les foreign keys
4. Mettre à jour les RLS policies

### Phase 3 : App Flutter (1 jour)
1. Modifier `AuthService` pour récupérer `app_user_id` après login
2. Stocker `app_user_id` localement (SharedPreferences)
3. Utiliser `app_user_id` pour toutes les opérations métier

```dart
// Exemple dans AuthService
class AuthService {
  Future<int?> getAppUserId() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;
    
    final response = await supabase
      .from('app_users')
      .select('id')
      .eq('auth_id', authUser.id)
      .single();
    
    return response['id'] as int;
  }
}
```

### Phase 4 : Mode Local-Only (1 jour)
Pour les users qui n'utilisent pas le cloud :

```dart
// Créer un app_user local sans auth_id
Future<int> createLocalUser() async {
  final db = await database;
  return await db.insert('app_users', {
    'auth_id': null,  // Pas de UUID pour local-only
    'email': 'local@device',
    'created_at': DateTime.now().toIso8601String(),
  });
}
```

### Phase 5 : Tests & Validation (1 jour)
1. Tester inscription cloud → auto-création app_users
2. Tester mode local-only
3. Tester sync cloud après utilisation locale
4. Valider RLS policies

## 📱 Impact sur l'App Flutter

### Changements Minimaux

```dart
// AVANT (UUID partout)
class Foyer {
  final int? id;  // UUID
  final String userId;  // UUID
}

// APRÈS (INT pour métier, UUID caché)
class Foyer {
  final int? id;  // INT auto-incrémenté
  final int userId;  // INT référence app_users
}

// AuthService gère le mapping UUID → INT en interne
```

### Avantages Code
- ✅ Pas de changement dans 95% du code
- ✅ Tests existants fonctionnent
- ✅ Performance maintenue
- ✅ Simplicité préservée

## 🎯 Décision à Prendre

### Questions pour l'Admin Supabase

1. **Colonnes UUID existantes** : 
   - ☐ Garder en parallèle pendant transition
   - ☐ Supprimer après migration complète

2. **Trigger auto-insert** :
   - ☐ Oui, créer trigger sur auth.users
   - ☐ Non, gérer manuellement dans l'app

3. **Scripts SQL** :
   - ☐ Oui, générer scripts complets de migration
   - ☐ Oui, inclure plan de rollback

### Ma Recommandation

**Option A : Migration Hybride (Recommandée)**
- Garder UUID en parallèle pendant 1-2 mois
- Créer trigger auto-insert
- Migration progressive table par table
- Supprimer UUID une fois stable

**Avantages** :
- Sécurité (rollback possible)
- Progressif (pas de big bang)
- Testable (validation incrémentale)

## 📊 Comparaison Solutions

| Critère | UUID Complet | INT Complet | **Hybride (Recommandé)** |
|---------|--------------|-------------|--------------------------|
| Complexité migration | ⚠️ Très haute | ✅ Aucune | ✅ Faible |
| Sécurité Auth | ✅ Excellente | ⚠️ Moyenne | ✅ Excellente |
| Performance | ⚠️ Moyenne | ✅ Excellente | ✅ Excellente |
| Compatibilité Supabase | ✅ Native | ⚠️ Limitée | ✅ Native |
| Tests à réécrire | ⚠️ 137+ | ✅ 0 | ✅ 0 |
| Mode local-only | ✅ Possible | ✅ Facile | ✅ Facile |
| Réversibilité | ⚠️ Difficile | ⚠️ Difficile | ✅ Facile |

## 🚀 Prochaines Étapes

### Immédiat
1. Confirmer l'approche hybride avec l'admin Supabase
2. Demander les scripts SQL complets
3. Créer une branche `feature/hybrid-id-mapping`

### Cette Semaine
1. Implémenter table `app_users` sur Supabase
2. Créer trigger et backfill
3. Tester avec 1-2 tables métier

### Semaine Prochaine
1. Migrer toutes les tables métier
2. Adapter AuthService dans Flutter
3. Tests complets

## 💡 Conclusion

La solution hybride est **clairement la meilleure** :
- ✅ Résout le problème UUID sans douleur
- ✅ Garde les avantages des deux approches
- ✅ Migration simple et réversible
- ✅ Permet de continuer le développement des features

**Recommandation : Adopter cette approche immédiatement**
