# Conception Fonctionnelle NgonNest – MVP Sprint 1

Version : v1.0 — 31 août 2025

Portée : MVP offline‑first pour l’application NgonNest (onboarding foyer, inventaire consommables & durables, rappels/alertes, budget basique et paramètres). Toutes les données sont stockées localement via SQLite.

## Objectifs

NgonNest aide les foyers à suivre leurs biens (consommables et durables), à anticiper les ruptures et à estimer le budget mensuel sans connexion internet. Le MVP vise à valider le besoin et servir de base pour des extensions (multi‑foyer, synchronisation, IA).

## Parcours utilisateurs

1. **Onboarding** : à la première utilisation, l’utilisateur renseigne le nombre de personnes (1–10), le type de logement (maison, appartement, chambre…), la langue (français, anglais) et le budget mensuel estimé (facultatif). Ces données créent une entrée dans la table `foyer`.

2. **Ajout d’un consommable** : l’utilisateur choisit une catégorie, saisit un nom, la quantité initiale, la date d’achat (facultative) sous forme de calendrier ou sous formes d'estimation j:m:y du temps qu'il a deja vecu, l’unité (pièce/g/ml) et la méthode de prévision :  
   – **fréquence** : nombre de jours entre les achats (`frequence_achat_jours`).  
   – **débit** : consommation journalière (`consommation_jour`) avec taille du conditionnement.
   L’application calcule automatiquement la date de rupture prévue (`date_rupture_prev`) et planifie une alerte trois jours avant.

3. **Ajout d’un bien durable** : saisie du nom, de la catégorie, de la date d’achat et de la durée de vie estimée en jours (`duree_vie_prev_jours`). Une alerte optionnelle avertit de la fin de vie.

4. **Mise à jour des quantités** : l’utilisateur peut décrémenter de 1 la quantité restante, saisir une quantité manuelle ou réaliser un réachat (qui remet la quantité et le dernier achat à jour).

5. **Consultation de l’inventaire** : listes séparées pour les consommables et les durables, avec recherche et filtres. Les articles avec alerte apparaissent en priorité.

6. **Alertes & rappels** : un processus quotidien à 09h00 calcule les ruptures prévues et envoie une notification locale si `date_rupture_prev – aujourd’hui ≤ seuil_alerte_jours` (3 par défaut) ou si `quantite_restante ≤ seuil_alerte_quantite`.

7. **Budget** : estimation mensuelle par consommable :  
   – pour la fréquence : `(prix_unitaire × 30 / frequence_achat_jours)`  
   – pour le débit : `(prix_unitaire × consommation_jour × 30 / taille_conditionnement)`
   Le total et le détail par catégorie s’affichent, avec ajustement manuel possible.

8. **Export / Import JSON** : export chiffré facultatif du foyer et de l’inventaire vers un fichier local; import pour restauration ou fusion.

## Modèle de données (SQLite)

- **foyer (id, nb_personnes, type_logement, budget_mensuel_estime, langue)** : un seul enregistrement actif.  
- **objet (id, id_foyer, nom, categorie, type, date_achat, duree_vie_prev_jours, date_rupture_prev, quantite_initiale, quantite_restante, unite, taille_conditionnement, prix_unitaire, methode_prevision, frequence_achat_jours, consommation_jour, seuil_alerte_jours, seuil_alerte_quantite)** : contient à la fois les biens durables et les consommables, différenciés par `type`.  
- **reachat_log (id, id_objet, date, quantite, prix_total)** (optionnel dans le MVP) : journal des réapprovisionnements.

## Règles métiers

- `nb_personnes` entre 1 et 10.  
- `langue` ∈ {fr, en}.  
- Pour les consommables :
  – Si `methode_prevision = frequence`, `frequence_achat_jours ≥ 1`.  
  – Si `methode_prevision = debit`, `consommation_jour > 0` et `taille_conditionnement > 0`.  
  – `date_rupture_prev` est recalculée après chaque mise à jour ou réachat.  
  – Quantité restante jamais négative.
- Pour les durables : option d’alerte sur la date d’expiration (`date_achat + duree_vie_prev_jours`).  
- `seuil_alerte_jours` par défaut = 3, modifiable globalement ou par objet.

## Architecture et technologies

- **Flutter** pour l’UI mobile (Android et iOS) avec un design simple (bottom tabs : Dashboard, Inventaire, Budget, Paramètres).  
- **SQLite** via `sqflite` pour la persistance locale (tables `foyer` et `objet`).  
- **Repository pattern** et services (`AlertService`, `PredictionService`) pour isoler la logique métier.  
- **Notifications locales** via `flutter_local_notifications`.  
- **Internationalisation** (français, anglais) dès le MVP.

## Critères d’acceptation (Sprint 1)

- Onboarding complet avec validations (champs obligatoires, format correct).  
- CRUD pour consommables et durables fonctionnel (création, édition, suppression).  
- Calcul et déclenchement des alertes à J-3 (notification affichée, badge sur dashboard).  
- Budget mensuel calculé et affiché par catégorie.  
- Fonctionnement hors ligne complet.  
- Application testée sur au moins trois appareils Android et un iOS; tests unitaires > 80 % de couverture; temps de réponse < 2 s.  
- Code et documentation poussés dans le dossier `/docs/specs` du dépôt.
  
