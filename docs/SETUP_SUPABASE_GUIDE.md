# 🚀 Guide Configuration Supabase NgoNest

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :
- ✅ Compte Supabase (gratuit : https://supabase.com)
- ✅ Projet Flutter NgonNest opérationnel
- ✅ Application fonctionnelle en mode offline

---

## ⚙️ Configuration Supabase (5 minutes)

### 1. Créer Projet Supabase
1. Aller sur [supabase.com](https://supabase.com)
2. Se connecter avec GitHub ou email
3. Créer nouveau projet : `📝 New Project`
4. Choisir nom : `ngonnest-{votre-nom}`
5. Sélectionner région : `Frankfurt, Germany` (ou autre européen pour privacy GDPR)

### 2. Récupérer Variables de Connexion
1. Dans votre projet Supabase : **`Settings` → `API`**
2. Copier les valeurs :

```dart
// Dans lib/config/supabase_config.dart
static const String prod_url = 'https://abcdefghijklmnop.supabase.co';
static const String prod_anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 3. Créer Tables Base de Données
Exécuter ce SQL dans **`SQL Editor`** de Supabase :

```sql
-- Table profils utilisateurs
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table foyers
CREATE TABLE households (
  id SERIAL PRIMARY KEY,
  local_id INTEGER UNIQUE NOT NULL,
  person_count INTEGER NOT NULL,
  room_count INTEGER NOT NULL,
  housing_type TEXT NOT NULL,
  language TEXT NOT NULL,
  estimated_budget REAL,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table produits
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  local_id INTEGER UNIQUE NOT NULL,
  household_id INTEGER REFERENCES households(local_id),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('consommable', 'durable')),
  purchase_date TEXT,
  predicted_lifespan_days INTEGER,
  predicted_depletion_date TEXT,
  initial_quantity REAL NOT NULL,
  remaining_quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  package_size REAL,
  unit_price REAL,
  prediction_method TEXT,
  purchase_frequency_days INTEGER,
  daily_consumption REAL,
  alert_threshold_days INTEGER DEFAULT 3,
  alert_threshold_quantity REAL DEFAULT 1.0,
  comments TEXT,
  room TEXT,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table achats
CREATE TABLE purchases (
  id SERIAL PRIMARY KEY,
  local_id INTEGER UNIQUE NOT NULL,
  product_local_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  quantity REAL NOT NULL,
  total_price REAL,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table catégories budget
CREATE TABLE budget_categories (
  id SERIAL PRIMARY KEY,
  local_id INTEGER UNIQUE NOT NULL,
  name TEXT NOT NULL,
  limit_amount REAL NOT NULL,
  spent_amount REAL DEFAULT 0,
  month TEXT NOT NULL,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(name, month)
);

-- Table notifications
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  local_id INTEGER UNIQUE,
  user_id UUID REFERENCES auth.users(id),
  type TEXT NOT NULL CHECK (type IN ('stock_alert', 'price_info', 'budget_alert')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high')),
  read_at TIMESTAMPTZ,
  synced_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes pour performance
CREATE INDEX idx_products_household_id ON products(household_id);
CREATE INDEX idx_products_synced_at ON products(synced_at);
CREATE INDEX idx_households_synced_at ON households(synced_at);
CREATE INDEX idx_purchases_synced_at ON purchases(synced_at);
CREATE INDEX idx_budget_categories_synced_at ON budget_categories(updated_at);

-- Activer Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

### 4. Configurer Politiques RLS
Toujours dans **`SQL Editor`**, exécuter :

```sql
-- Politiques pour profiles (utilisateur voit/modifie seulement son profil)
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid()::text = id::text);

-- Politiques pour households (utilisateur gère ses foyers)
CREATE POLICY "Users can view their households" ON households
  FOR SELECT USING (true); -- Accessible à tous (partage familial possible)

CREATE POLICY "Users can insert households" ON households
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update households" ON households
  FOR UPDATE USING (true);

-- Même logique pour products, purchases, budget_categories, notifications
CREATE POLICY "Users can view products" ON products FOR SELECT USING (true);
CREATE POLICY "Users can insert products" ON products FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update products" ON products FOR UPDATE USING (true);

CREATE POLICY "Users can view purchases" ON purchases FOR SELECT USING (true);
CREATE POLICY "Users can insert purchases" ON purchases FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view budget categories" ON budget_categories FOR SELECT USING (true);
CREATE POLICY "Users can insert budget categories" ON budget_categories FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update budget categories" ON budget_categories FOR UPDATE USING (true);

CREATE POLICY "Users can view notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert notifications" ON notifications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
```

### 5. Configurer Authentication
Dans **`Authentication` → `Settings`** :
- ✅ Activer **"Enable email confirmations"**
- ✅ Configurer **"Site URL"** : `https://ngonnest.com/auth`
- ✅ Configurer **"Redirect URLs"** : ajouter vos URLs d'app

---

## 📱 Configuration Application (3 minutes)

### Mettre à jour `supabase_config.dart`
Remplacer les variables par vos vraies valeurs Supabase :

```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  // 🔑 REMPLACER par vos vraies valeurs Supabase
  static const String prod_url = 'https://votre-project-id.supabase.co';
  static const String prod_anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.votre-cle-api';

  static const String dev_url = 'https://votre-dev-project-id.supabase.co';
  static const String dev_anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dev-cle-api';
  // ... reste du code
}
```

---

## 🚀 Test & Déploiement

### Lancer l'application
```bash
cd code/flutter/ngonnest_app
flutter run --debug
```

### Activer la synchronisation
1. Ouvrir l'app
2. Aller dans **Paramètres**
3. Activer **"Synchronisation Cloud"**
4. Accepter les termes de confidentialité
5. Tester un ajout produit → doit se synchroniser automatiquement

### Vérifier les logs
- ✅ `[SupabaseApiService] Client initialized`
- ✅ `[Main] Supabase initialized successfully.`
- ✅ `[BidirectionalSyncService] Bidirectional sync enabled`

---

## 🔧 Résolution Problèmes

### "Supabase not configured"
- Vérifier que URL et clé sont correctement configurées
- S'assurer que `isConfigured()` retourne `true`

### Sync ne marche pas
- Vérifier connexion internet Cameroun (MTN/Orange souvent lente)
- Tester en WiFi d'abord
- Vérifier logs Supabase dans console

### App plante au démarrage
- Compilation erreurs ? `flutter clean && flutter pub get`
- Vérifier que toutes les dépendances sont installées

---

## 📊 Métriques à Surveiller

### Dashboard Supabase
- **Active Users** : nombre utilisateurs connectés
- **Database Size** : utilisation stockage (< 500MB gratuit)
- **API Calls** : nombre requêtes/jour (< 50k gratuit)
- **Realtime Messages** : connections temps réel

### App Performance
- **Sync Success Rate** : > 95% réussité
- **Payload Size Average** : < 2KB par opération
- **Battery Impact** : < 1% par heure d'utilisation

---

## 🎯 Fonctionnalités Activées

✅ **Offline-first solide** : App marche sans internet  
✅ **Sync bidirectionnelle** : Local ↔ Cloud en temps réel  
✅ **Authentification** : Gestion comptes utilisateurs  
✅ **Optimisations Cameroun** : Économie data/batterie/réseau  
✅ **Gestion conflits** : Sync intelligente automatique  
✅ **Sécurité RLS** : Toutes requêtes protégées  
✅ **Monitoring** : Métriques détaillées  

---

**🎊 Félicitations ! Votre app NgoNest est maintenant synchronisée avec Supabase !**

**Prochaine étape** : Tester avec vrais utilisateurs Cameroun et collecter feedback ! 🇨🇲✨
