# NgonNest Database Schema - Version 12 (Pre-UUID)

## Overview

This document describes the current database schema at version 12, before the UUID migration. This serves as a reference for the migration process and for understanding the data structure.

**Database Type**: SQLite  
**Current Version**: 12  
**Primary Key Type**: INTEGER (AUTOINCREMENT)  
**Migration Target**: Version 13 (UUID-based TEXT primary keys)

---

## Tables

### 1. foyer

Stores household information.

**Schema:**
```sql
CREATE TABLE foyer (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nb_personnes INTEGER NOT NULL,
  nb_pieces INTEGER NOT NULL DEFAULT 1,
  type_logement TEXT NOT NULL,
  langue TEXT NOT NULL,
  budget_mensuel_estime REAL
)
```

**Columns:**
- `id` (INTEGER, PK): Unique household identifier
- `nb_personnes` (INTEGER): Number of people in household
- `nb_pieces` (INTEGER): Number of rooms (default: 1)
- `type_logement` (TEXT): Housing type (e.g., 'appartement', 'maison')
- `langue` (TEXT): Language preference (e.g., 'fr', 'en', 'es')
- `budget_mensuel_estime` (REAL): Estimated monthly budget in FCFA

**Indexes:** None

**Foreign Keys:** None

**Sample Data:**
```
id=1, nb_personnes=4, nb_pieces=5, type_logement='appartement', langue='fr', budget_mensuel_estime=150000.0
```

---

### 2. objet

Stores household inventory items (products).

**Schema:**
```sql
CREATE TABLE objet (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_foyer INTEGER NOT NULL,
  nom TEXT NOT NULL,
  categorie TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('consommable', 'durable')),
  date_achat TEXT,
  duree_vie_prev_jours INTEGER,
  date_rupture_prev TEXT,
  quantite_initiale REAL NOT NULL,
  quantite_restante REAL NOT NULL CHECK (quantite_restante >= 0),
  unite TEXT NOT NULL,
  taille_conditionnement REAL,
  prix_unitaire REAL,
  methode_prevision TEXT CHECK (methode_prevision IN ('frequence', 'debit')),
  frequence_achat_jours INTEGER,
  consommation_jour REAL,
  seuil_alerte_jours INTEGER DEFAULT 3,
  seuil_alerte_quantite REAL DEFAULT 1,
  commentaires TEXT,
  date_modification TEXT,
  room TEXT,
  FOREIGN KEY (id_foyer) REFERENCES foyer (id)
)
```

**Columns:**
- `id` (INTEGER, PK): Unique product identifier
- `id_foyer` (INTEGER, FK): Reference to foyer table
- `nom` (TEXT): Product name
- `categorie` (TEXT): Product category (e.g., 'Alimentation', 'Hygiène')
- `type` (TEXT): Product type ('consommable' or 'durable')
- `date_achat` (TEXT): Purchase date (ISO 8601)
- `duree_vie_prev_jours` (INTEGER): Predicted lifespan in days
- `date_rupture_prev` (TEXT): Predicted stockout date (ISO 8601)
- `quantite_initiale` (REAL): Initial quantity
- `quantite_restante` (REAL): Remaining quantity (≥ 0)
- `unite` (TEXT): Unit of measurement (e.g., 'kg', 'L', 'pièce')
- `taille_conditionnement` (REAL): Package size
- `prix_unitaire` (REAL): Unit price in FCFA
- `methode_prevision` (TEXT): Prediction method ('frequence' or 'debit')
- `frequence_achat_jours` (INTEGER): Purchase frequency in days
- `consommation_jour` (REAL): Daily consumption rate
- `seuil_alerte_jours` (INTEGER): Alert threshold in days (default: 3)
- `seuil_alerte_quantite` (REAL): Alert threshold quantity (default: 1)
- `commentaires` (TEXT): User comments
- `date_modification` (TEXT): Last modification date (ISO 8601)
- `room` (TEXT): Room location

**Indexes:**
- `idx_objet_foyer` on `id_foyer`
- `idx_objet_categorie` on `categorie`
- `idx_objet_type` on `type`
- `idx_objet_date_rupture` on `date_rupture_prev`
- `idx_objet_quantite` on `quantite_restante`

**Foreign Keys:**
- `id_foyer` → `foyer(id)`

**Sample Data:**
```
id=1, id_foyer=1, nom='Riz', categorie='Alimentation', type='consommable', 
quantite_initiale=10.0, quantite_restante=5.0, unite='kg', prix_unitaire=1500.0
```

---

### 3. budget_categories

Stores budget categories and spending limits.

**Schema:**
```sql
CREATE TABLE budget_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  limit_amount REAL NOT NULL,
  spent REAL NOT NULL DEFAULT 0,
  percentage REAL NOT NULL DEFAULT 0.25,
  month TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(name, month)
)
```

**Columns:**
- `id` (INTEGER, PK): Unique category identifier
- `name` (TEXT): Category name (e.g., 'Alimentation', 'Hygiène')
- `limit_amount` (REAL): Budget limit in FCFA
- `spent` (REAL): Amount spent in FCFA (default: 0)
- `percentage` (REAL): Percentage of total budget (default: 0.25)
- `month` (TEXT): Month in YYYY-MM format
- `created_at` (TEXT): Creation timestamp (ISO 8601)
- `updated_at` (TEXT): Last update timestamp (ISO 8601)

**Indexes:**
- `idx_budget_month` on `month`
- `idx_budget_name_month` on `(name, month)`

**Constraints:**
- UNIQUE constraint on `(name, month)` combination

**Foreign Keys:** None

**Sample Data:**
```
id=1, name='Alimentation', limit_amount=50000.0, spent=15000.0, 
percentage=0.33, month='2024-01'
```

---

### 4. alertes

Stores user notifications and alerts.

**Schema:**
```sql
CREATE TABLE alertes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_objet INTEGER,
  type_alerte TEXT NOT NULL CHECK (type_alerte IN ('stock_faible', 'expiration_proche', 'reminder', 'system')),
  titre TEXT NOT NULL,
  message TEXT NOT NULL,
  urgences TEXT NOT NULL CHECK (urgences IN ('low', 'medium', 'high')) DEFAULT 'medium',
  date_creation TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  date_lecture TEXT,
  lu INTEGER NOT NULL DEFAULT 0,
  resolu INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (id_objet) REFERENCES objet (id) ON DELETE CASCADE
)
```

**Columns:**
- `id` (INTEGER, PK): Unique alert identifier
- `id_objet` (INTEGER, FK, nullable): Reference to objet table
- `type_alerte` (TEXT): Alert type ('stock_faible', 'expiration_proche', 'reminder', 'system')
- `titre` (TEXT): Alert title
- `message` (TEXT): Alert message
- `urgences` (TEXT): Urgency level ('low', 'medium', 'high')
- `date_creation` (TEXT): Creation timestamp (ISO 8601)
- `date_lecture` (TEXT, nullable): Read timestamp (ISO 8601)
- `lu` (INTEGER): Read flag (0 or 1)
- `resolu` (INTEGER): Resolved flag (0 or 1)

**Indexes:**
- `idx_alertes_objet` on `id_objet`
- `idx_alertes_type` on `type_alerte`
- `idx_alertes_lu` on `lu`
- `idx_alertes_date` on `date_creation`

**Foreign Keys:**
- `id_objet` → `objet(id)` ON DELETE CASCADE

**Sample Data:**
```
id=1, id_objet=1, type_alerte='stock_faible', titre='Stock faible', 
message='Le stock de Riz est faible', urgences='medium', lu=0, resolu=0
```

---

### 5. reachat_log

Stores purchase history for products.

**Schema:**
```sql
CREATE TABLE reachat_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_objet INTEGER NOT NULL,
  date TEXT NOT NULL,
  quantite REAL NOT NULL,
  prix_total REAL,
  FOREIGN KEY (id_objet) REFERENCES objet (id)
)
```

**Columns:**
- `id` (INTEGER, PK): Unique log entry identifier
- `id_objet` (INTEGER, FK): Reference to objet table
- `date` (TEXT): Purchase date (ISO 8601)
- `quantite` (REAL): Quantity purchased
- `prix_total` (REAL, nullable): Total price in FCFA

**Indexes:**
- `idx_reachat_objet` on `id_objet`
- `idx_reachat_date` on `date`

**Foreign Keys:**
- `id_objet` → `objet(id)`

**Sample Data:**
```
id=1, id_objet=1, date='2024-01-01', quantite=10.0, prix_total=15000.0
```

---

### 6. product_prices

Stores reference prices for products.

**Schema:**
```sql
CREATE TABLE product_prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  price_fcfa REAL NOT NULL,
  price_euro REAL NOT NULL,
  unit TEXT NOT NULL DEFAULT 'piece',
  brand TEXT,
  description TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
)
```

**Columns:**
- `id` (INTEGER, PK): Unique price entry identifier
- `name` (TEXT): Product name
- `category` (TEXT): Product category
- `price_fcfa` (REAL): Price in FCFA
- `price_euro` (REAL): Price in EUR
- `unit` (TEXT): Unit of measurement (default: 'piece')
- `brand` (TEXT, nullable): Brand name
- `description` (TEXT, nullable): Product description
- `created_at` (TEXT): Creation timestamp (ISO 8601)
- `updated_at` (TEXT): Last update timestamp (ISO 8601)

**Indexes:**
- `idx_product_prices_name` on `name`
- `idx_product_prices_category` on `category`
- `idx_product_prices_name_category` on `(name, category)`

**Foreign Keys:** None

**Sample Data:**
```
id=1, name='Riz', category='Alimentation', price_fcfa=1500.0, 
price_euro=2.29, unit='kg'
```

---

### 7. sync_outbox

Stores pending sync operations for offline-first functionality.

**Schema:**
```sql
CREATE TABLE sync_outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_type TEXT NOT NULL CHECK (operation_type IN ('CREATE', 'UPDATE', 'DELETE')),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('objet', 'foyer', 'reachat_log', 'budget_categories')),
  entity_id INTEGER NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_retry_at TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'syncing', 'synced', 'failed')) DEFAULT 'pending',
  error_message TEXT
)
```

**Columns:**
- `id` (INTEGER, PK): Unique outbox entry identifier
- `operation_type` (TEXT): Operation type ('CREATE', 'UPDATE', 'DELETE')
- `entity_type` (TEXT): Entity type ('objet', 'foyer', 'reachat_log', 'budget_categories')
- `entity_id` (INTEGER): ID of the entity being synced
- `payload` (TEXT): JSON payload of the operation
- `created_at` (TEXT): Creation timestamp (ISO 8601)
- `retry_count` (INTEGER): Number of retry attempts (default: 0)
- `last_retry_at` (TEXT, nullable): Last retry timestamp (ISO 8601)
- `status` (TEXT): Sync status ('pending', 'syncing', 'synced', 'failed')
- `error_message` (TEXT, nullable): Error message if failed

**Indexes:**
- `idx_outbox_status` on `status`
- `idx_outbox_created` on `created_at`
- `idx_outbox_entity` on `(entity_type, entity_id)`

**Foreign Keys:** None (entity_id is a generic reference)

**Sample Data:**
```
id=1, operation_type='CREATE', entity_type='objet', entity_id=1, 
payload='{"id":1,"nom":"Riz"}', status='pending', retry_count=0
```

---

## Entity Relationships

```
foyer (1) ──< (N) objet
objet (1) ──< (N) alertes
objet (1) ──< (N) reachat_log
```

**Key Relationships:**
1. One foyer can have many objets (household items)
2. One objet can have many alertes (notifications)
3. One objet can have many reachat_log entries (purchase history)
4. budget_categories, product_prices, and sync_outbox are independent tables

---

## Migration Considerations for UUID (v13)

### Tables Requiring ID Migration

All tables with INTEGER PRIMARY KEY will be migrated to TEXT (UUID):

1. **foyer**: `id` INTEGER → TEXT
2. **objet**: `id` INTEGER → TEXT, `id_foyer` INTEGER → TEXT
3. **budget_categories**: `id` INTEGER → TEXT
4. **alertes**: `id` INTEGER → TEXT, `id_objet` INTEGER → TEXT
5. **reachat_log**: `id` INTEGER → TEXT, `id_objet` INTEGER → TEXT
6. **product_prices**: `id` INTEGER → TEXT
7. **sync_outbox**: `id` INTEGER → TEXT, `entity_id` INTEGER → TEXT

### Foreign Key Dependencies

Migration order must respect foreign key constraints:

1. **foyer** (no dependencies)
2. **objet** (depends on foyer)
3. **budget_categories** (independent)
4. **product_prices** (independent)
5. **alertes** (depends on objet)
6. **reachat_log** (depends on objet)
7. **sync_outbox** (references all, but no FK constraint)

### Data Integrity Checks

Before migration:
- Verify all foreign key relationships are valid
- Count records in each table
- Check for orphaned records

After migration:
- Verify record counts match
- Verify all UUIDs are valid v4 format
- Verify foreign key relationships maintained
- Verify no data loss

---

## Statistics (Typical Production Database)

| Table | Typical Record Count | Growth Rate |
|-------|---------------------|-------------|
| foyer | 1-5 | Stable |
| objet | 50-500 | Medium |
| budget_categories | 10-50 | Low |
| alertes | 20-200 | High |
| reachat_log | 100-1000 | High |
| product_prices | 100-500 | Low |
| sync_outbox | 0-100 | Variable |

---

## Version History

- **v1**: Initial schema (foyer, objet, reachat_log)
- **v2**: Added alertes table
- **v3**: Added alert thresholds to objet
- **v4**: Added commentaires to objet
- **v5**: Verified commentaires column
- **v6**: Added budget_categories table
- **v7**: Added date_modification to objet
- **v8**: Added product_prices table
- **v9**: Added performance indexes
- **v10**: Added room column to objet
- **v11**: Added sync_outbox table
- **v12**: Added percentage column to budget_categories
- **v13**: (Planned) UUID migration

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-15  
**Author**: NgonNest Development Team
