# NGONNEST – TASKS V3+ (LONG-TERME)

> Ce fichier contient les tâches V3+ (cloud sync, multi-device, entreprise).
> À travailler UNIQUEMENT après V2 complet et feedback utilisateurs positif.
> Respecte AI_RULES.md et requirements.md (V3.*).

## 0. Prérequis V3+

AVANT de commencer toute tâche V3, vérifier que :
- ✅ V1 et V2 sont 100% terminés
- ✅ Au moins 1000 utilisateurs actifs
- ✅ Feedback utilisateurs demandant features cloud/multi-device
- ✅ Infrastructure cloud (Supabase) prête et testée

---

## Phase V3.1: Cloud Sync (Semaines 23-26)

### Task 3.1: Synchronisation Cloud (Supabase)

**Liée à** : Requirement V3.1 (Cloud Sync)

- [ ] **3.1.1** Configurer Supabase backend
  - Créer projet Supabase
  - Définir schéma tables : `households`, `products`, `budgets`, `sync_queue`
  - Configurer Row Level Security (RLS)
  - Créer fonctions Edge pour sync logic

- [ ] **3.1.2** Implémenter queue de synchronisation locale
  - Table SQLite `sync_queue` : operation (insert/update/delete), table, record_id, timestamp
  - Service `SyncQueueService` pour enregistrer opérations offline

- [ ] **3.1.3** Implémenter sync bidirectionnelle
  - Upload : envoyer opérations queue vers Supabase
  - Download : récupérer changements depuis Supabase
  - Conflict resolution : local wins par défaut (configurable)

- [ ] **3.1.4** UI Opt-in Cloud Sync
  - Écran "Activer Cloud Sync" avec explication claire privacy
  - Consentement explicite utilisateur
  - Toggle dans Settings pour activer/désactiver

- [ ] **3.1.5** Tests sync
  - Test offline → online : queue vidée correctement
  - Test conflicts : résolution cohérente
  - Test multi-device : changements propagés

#### Tests pour Task 3.1
- [ ] Integration test : sync 2 devices
- [ ] Conflict resolution test
- [ ] F2P/P2F checks

---

## Phase V3.2: Multi-User & Partage Famille (Semaines 27-28)

### Task 3.2: Family Sharing

**Liée à** : Requirement V3.2 (Family Sharing)

- [ ] **3.2.1** Système d'invitations
  - Générer code invite unique par household
  - Partager code via WhatsApp/Email
  - Rejoindre household avec code

- [ ] **3.2.2** Gestion permissions
  - Rôles : Admin, Membre, Viewer
  - Admin peut inviter/révoquer membres
  - Membres peuvent add/edit produits
  - Viewers read-only

- [ ] **3.2.3** Historique modifications multi-user
  - Enregistrer `user_id` sur chaque modification
  - Afficher "Modifié par [Nom]" dans historique

#### Tests pour Task 3.2
- [ ] Integration test : invitation + join household
- [ ] Test permissions rôles
- [ ] F2F/P2F checks

---

## Phase V3.3: Mode Entreprise (Hôtels/Restos) (Semaines 29-32)

### Task 3.3: Hotel/Restaurant Mode

**Liée à** : Requirement V3.3 (Enterprise Mode)

- [ ] **3.3.1** Gestion multi-espaces
  - Concept "Espace" : Chambre 101, Cuisine, Bar, etc.
  - CRUD espaces
  - Inventaire par espace

- [ ] **3.3.2** Analytics avancées
  - Rapports : consommation par espace, par période
  - Graphiques : trends, comparaisons
  - Export Excel

- [ ] **3.3.3** Intégration WhatsApp Business (optionnel)
  - Notifications rupture stock via WhatsApp
  - API WhatsApp Business
  - Configuration webhook

#### Tests pour Task 3.3
- [ ] Integration test multi-espaces
- [ ] Analytics correctness tests
- [ ] F2P/P2F checks

---

**FIN TASKS V3+**

---

## Roadmap Future (V4+)

- IA avancée : suggestions menus, optimisation achats
- Intégrations e-commerce : achat direct depuis app
- Mode offline avancé : sync différentielle optimisée
- Support multilingue complet : 10+ langues africaines
