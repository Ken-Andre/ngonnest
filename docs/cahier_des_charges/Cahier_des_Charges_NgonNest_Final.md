# Cahier des charges NgonNest

### 1. Introduction

#### 1.1 Objectif

Ce cahier des charges définit les **exigences fonctionnelles et non fonctionnelles** de **NgonNest**, une application mobile évolutive de gestion domestique conçue pour réduire la charge mentale des foyers en automatisant la gestion des ravitaillements ménagers (produits d'entretien, biens durables) et, à terme, alimentaires. NgonNest vise à offrir une solution **simple**, **intuitive**, et **adaptée au contexte local** (Cameroun, puis Afrique centrale), avec une portée internationale future (Canada, France, et potentiellement Asie via les stores d'applications). L'application repose sur une **expérience utilisateur accessible** (test : "Est-ce que ma mère de 52 ans comprendrait en 30 secondes ?"), un **fonctionnement hors ligne** pour les fonctionnalités de base, et un modèle économique **freemium** durable (Basic gratuit, Pro à 600 FCFA/mois ou 6k FCFA/an au Cameroun, ajustable pour d'autres marchés). Ce document servira de **référence centrale** pour le développement, les évaluations des prestations, et les transitions d'équipe.

#### 1.2 Contexte

Le Cameroun affiche une adoption numérique croissante, avec **12,89 millions d'internautes** en 2023 et un taux de pénétration des smartphones de **75%** en 2025, principalement en milieu urbain (17,4 millions de personnes, 58% de la population) \[Source: DataReportal 2023, Gr_expert_Feedreport.pdf\]. Les foyers urbains, notamment les mères de famille, les étudiants, et les jeunes actifs, font face à des **pain points** : oublis de ravitaillements, charge mentale, et gaspillage, dans un contexte de budgets contraints et de connexions Internet instables. NgonNest répond à ces besoins avec une solution **légère**, **privacy-first** (données locales, synchronisation optionnelle), et adaptée aux réalités économiques et culturelles locales (prix en FCFA). À long terme, l'application s'étendra à l'Afrique centrale (Gabon, RDC) et à des marchés internationaux (Canada, France), en s'appuyant sur des partenariats organiques (ex. : diaspora camerounaise) et une scalabilité via les stores d'applications mondiaux.

#### 1.3 Portée

NgonNest est une application mobile pour **Android 8.0+** et **iOS 13+**, avec une **feuille de route évolutive** :

- **MVP (Phase 1, 4 mois)** : Gestion ménagère (inventaire de biens durables/consommables, rappels manuels, budget basique), focalisée sur le Cameroun (Yaoundé, Douala).
- **Phase 2 (Mois 5-12)** : Améliorations (prédictions statistiques, synchronisation cloud optionnelle) et expansion en Afrique centrale.
- **Phase 3 (Mois 13+)** : Fonctionnalités alimentaires (V2) et déploiement international (Canada, France, potentiellement Asie), avec adaptations locales (langues, devises, habitudes culturelles). L'application privilégie :
- **Performance hors ligne** via SQLite pour le stockage local.
- **Simplicité** : Onboarding en 2 minutes, interface multilingue (français, anglais, ewondo, duala), navigation intuitive.
- **Scalabilité** : Architecture extensible (Flutter, Supabase) pour intégrer des fonctionnalités futures (IA prédictive, synchronisation multi-devices, analyses avancées).
- **Branding** : Nom "NgonNest" (racines camerounaises, internationalement mémorable) pour un référencement fort sur les stores d'applications.

#### 1.4 Contraintes Clés

- **Techniques** : Application légère (&lt;25 Mo), compatible avec des appareils à faible capacité (2 Go RAM minimum). Fonctionnalités de base 100% hors ligne, avec synchronisation optionnelle via Supabase.
- **Marché** : Adoption par un public semi-technophile (mères urbaines, étudiants) dans un contexte de méfiance envers les applications complexes. Expansion internationale nécessitant des adaptations culturelles et monétaires.
- **Budget** : Coût initial hors recrutement estimé à **10  USD** pour le MVP (développement, design, tests). Marketing initial à 200 000 FCFA. Coûts futurs à ajuster pour les phases d'expansion.
- **Réglementaires** : Respect des principes de confidentialité (données locales, consentement explicite pour la synchronisation, aucune collecte non essentielle).

#### 1.5 Critère de Validation Ultime

Chaque fonctionnalité doit passer le test : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"** Si la réponse est non, la fonctionnalité sera simplifiée ou reportée.

### 2. Description Générale

#### 2.1 Public Cible

NgonNest s’adresse à des segments d’utilisateurs spécifiques, avec une priorisation claire pour le marché initial (Cameroun) et une vision d’adaptation pour les expansions régionales et internationales :

- **Principal** : **Mères de famille urbaines (25-45 ans)**, résidant à Yaoundé et Douala, semi-technophiles (habituées à WhatsApp et Mobile Money), avec une charge mentale élevée liée à la gestion du foyer et des budgets contraints. Ce segment représente la majorité de la classe moyenne émergente (\~25% de la population urbaine, \~4,35 millions de personnes) \[Source: Gr_expert_Feedreport.pdf\].
- **Secondaire** : **Étudiants et jeunes actifs (20-30 ans)**, technophiles, vivant dans leurs premiers logements (appartements ou colocations), sensibles à la simplicité et à la budgétisation. Ce segment est en croissance avec l’urbanisation (3,6%/an) \[Source: Gr_expert_Feedreport.pdf\].
- **Premium (Phase 3)** : **Familles expatriées** (revenus élevés, habitudes occidentales/orientales) et diaspora camerounaise au Canada/France, pour une expansion internationale. Ce segment nécessitera des adaptations culturelles (ex. : interface en anglais/français uniquement, devises ajustées).

Chaque fonctionnalité sera validée via le test : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"**

#### 2.2 Environnement Technique

L’environnement technique est conçu pour être **léger**, **scalable**, et adapté aux contraintes locales (connexions instables, appareils à faible capacité), tout en permettant une évolution vers des fonctionnalités avancées et une portée internationale :

- **Plateformes** : Android 8.0+ et iOS 13+, couvrant \~75% des smartphones au Cameroun en 2025 \[Source: Gr_expert_Feedreport.pdf\]. Compatibilité future avec interfaces web/PC pour les marchés internationaux (Canada, France).
- **Langues** : Français, anglais, ewondo, duala pour le marché camerounais (MVP). Ajout de langues supplémentaires (ex. : lingala pour RDC, langues asiatiques pour phase 3) selon les besoins d’expansion.
- **Pays** : Cameroun ou les prix y seront pris. Ajout de pays (Congo, Tchad,France, Canada,...) pour l'expansion.
- **Technologies** :
  - **Frontend** : Flutter pour une interface cohérente et performante sur Android/iOS, avec un développement cross-platform économique.
  - **Backend local** : SQLite pour le stockage hors ligne des données (profils, inventaire, rappels, budget).
  - **Backend cloud (optionnel)** : Supabase (freemium, 500 MB gratuit, authentification, real-time) pour la synchronisation chiffrée des utilisateurs premium.
  - **IA (Phase 2+)** : TensorFlow Lite pour des prédictions locales basiques (ex. : consommation moyenne des produits), évolutif vers des modèles plus avancés.
- **Connexion** : Mode hors ligne pour toutes les fonctionnalités de base (MVP). Synchronisation cloud optionnelle pour les utilisateurs premium (Phase 2+), avec consentement explicite.

#### 2.3 Contraintes

- **Techniques** :
  - Taille de l’application : &lt;25 Mo pour garantir la compatibilité avec des appareils à faible capacité (2 Go RAM minimum).
  - Performance : Temps de chargement &lt;2 secondes sur un appareil milieu de gamme (ex. : Samsung Galaxy A12).
  - Consommation énergétique : &lt;1% de batterie par jour en usage standard.
- **Marché** :
  - Adoption initiale : Public semi-technophile avec méfiance potentielle envers les applications complexes. Onboarding intuitif (2 minutes maximum).
  - Expansion régionale/internationale : Nécessité d’adaptations culturelles (langues, devises, habitudes) pour l’Afrique centrale (Gabon, RDC) et les marchés internationaux (Canada, France, Asie).
- **Budget** :
  - Coût initial hors recrutement : 10 00 USD pour le MVP (développement, design, tests).
  - Marketing initial : 20 000 FCFA pour des campagnes hyper-locales (WhatsApp, bouche-à-oreille, partenariats avec épiceries).
  - Coûts futurs : À estimer pour les phases 2 (améliorations) et 3 (expansion internationale).
- **Réglementaires** :
  - Confidentialité : Données stockées localement, cryptage AES-256, aucun partage sans consentement explicite. Conformité aux réglementations locales et internationales (ex. : RGPD pour l’expansion en France).
- **Culturelles** :
  - Interface adaptée aux réalités camerounaises (ex. : catégories d’articles ménagers locaux, comme le savon artisanal ou les balais traditionnels).
  - Validation continue via tests terrain avec des familles locales (dès la semaine 3-4 avec prototype cliquable).


### 3. Exigences Fonctionnelles

Les exigences fonctionnelles sont organisées en **épics** correspondant aux fonctionnalités clés du MVP (Phase 1, 4 mois), focalisées sur la gestion ménagère pour le marché camerounais. Chaque épic inclut des **user stories** classées en **Must** (essentiel pour le MVP), **Should** (améliorations souhaitables si budget/temps permettent), et **Could** (optionnel, pour phases futures). Toutes les fonctionnalités respectent le critère : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette fonctionnalité en moins de 30 secondes ?"** Les évolutions futures (ex. : alimentation en V2) sont mentionnées pour scalabilité.

#### 3.1 Epic 1 : Onboarding & Profil Foyer

**Objectif** : Permettre à l’utilisateur de configurer rapidement son foyer pour personnaliser l’expérience.

- **US-1.1 (Must)** : En tant que nouvelle utilisatrice, je veux créer un profil foyer en 2 minutes maximum, pour commencer à utiliser l’application immédiatement.

  - **Critères d’acceptation** :
    - Formulaire simple : nombre de personnes, type de logement (appartement/maison), nombre de pièces (chambres, salles de bain, salon, cuisine, custom).
    - Interface intuitive avec sliders ou listes déroulantes pour estimations (ex. : taille pièce : petit/moyen/grand) avec illustrations pour plus de rapidite dans les choix.
    - Pays et langue sélectionnable (français, anglais, ...) modifiable meme apres l'onboarding des le dashboard.
    - Validation en &lt;30 secondes par une mère de 52 ans via tests terrain.
  - **Priorité** : P1 (essentiel pour le MVP).

- **US-1.2 (Should)** : En tant qu’utilisatrice, je veux recevoir des recommandations initiales de produits ménagers basées sur mon profil foyer, pour faciliter mon premier inventaire.

  - **Critères d’acceptation** :
    - Suggestions basées sur règles métier (ex. : 4 personnes + 2 salles de bain → 6 rouleaux de papier toilette/mois).
    - Possibilité de rejeter/modifier les suggestions en 1 clic.
    - Données prédéfinies tirées de moyennes globales (ex. : savon, détergent).
  - **Priorité** : P2 (si temps/budget permettent).

- **US-1.3 (Could)** : En tant qu’utilisatrice premium, je veux synchroniser mon profil sur plusieurs appareils, pour partager avec ma famille.Un peu comme sur Spotify, ou le casting des tv Lg.

  - **Critères d’acceptation** :
    - Synchronisation chiffrée via Supabase (consentement explicite).
    - Support jusqu’à 6 comptes familiaux (Phase 2).
  - **Priorité** : P3 (Phase 2+).

#### 3.2 Epic 2 : Inventaire Ménager

**Objectif** : Permettre à l’utilisateur de gérer un inventaire de biens durables et consommables avec simplicité.

- **US-2.1 (Must)** : En tant qu’utilisatrice, je veux ajouter, modifier, ou supprimer des articles ménagers (durables/consommables), pour suivre mon stock.

  - **Critères d’acceptation** :
    - Ajout manuel : nom, catégorie (ex. : cuisine, salle de bain), type (durable/consommable), état/durée de vie estimée.
    - Interface avec champs pré-remplis (ex. : TV, savon, balai) et option custom.
    - Scan photo/code-bar (optionnel) pour identifier les articles (stockage local).
    - Validation en &lt;30 secondes via tests terrain.
  - **Priorité** : P1.

- **US-2.2 (Must)** : En tant qu’utilisatrice, je veux catégoriser mes articles par pièce et type, pour organiser mon inventaire facilement.

  - **Critères d’acceptation** :
    - Catégories prédéfinies (ex. : cuisine, salle de bain) et personnalisables.
    - Navigation intuitive (ex. : liste ou grille visuelle).
    - Temps d’ajout/catégorisation &lt;15 secondes par article.
  - **Priorité** : P1.

- **US-2.3 (Should)** : En tant qu’utilisatrice, je veux estimer la durée de vie restante d’un bien durable, pour planifier son remplacement.

  - **Critères d’acceptation** :
    - Champ pour saisir la date d’achat ou l’âge estimé de l’article.
    - Calcul simple (ex. : TV durée moyenne 5 ans → alerte à 4,5 ans).
    - Données basées sur moyennes locales ou saisie manuelle.
  - **Priorité** : P2.

- **US-2.4 (Could)** : En tant qu’utilisatrice, je veux ajouter des articles non répertoriés via un formulaire custom, pour couvrir des produits locaux spécifiques.

  - **Critères d’acceptation** :
    - Formulaire flexible (nom, catégorie, durée de vie estimée, fréquence d’achat).
    - Intégration dans la base locale pour réutilisation future.
  - **Priorité** : P3 (Phase 2).

#### 3.3 Epic 3 : Rappels & Alertes

**Objectif** : Fournir des rappels simples pour éviter les ruptures de stock.

- **US-3.1 (Must)** : En tant qu’utilisatrice, je veux recevoir des notifications locales pour les consommables proches de la rupture, pour planifier mes achats.

  - **Critères d’acceptation** :
    - Saisie manuelle de la fréquence d’achat (ex. : savon, 1 mois).
    - Notification push 3-5 jours avant la date estimée.
    - 3 alertes maximum affichées sur le dashboard.
    - Validation en &lt;30 secondes via tests terrain.
  - **Priorité** : P1.

- **US-3.2 (Should)** : En tant qu’utilisatrice, je veux une liste de courses générée automatiquement à partir des rappels, pour simplifier mes achats.

  - **Critères d’acceptation** :
    - Liste exportable vers calendrier natif ou WhatsApp.
    - Édition manuelle avant validation.
  - **Priorité** : P2.

- **US-3.3 (Could)** : En tant qu’utilisatrice premium, je veux des rappels prédictifs basés sur mes habitudes, pour plus de précision.

  - **Critères d’acceptation** :
    - Prédictions via règles statistiques (ex. : moyenne de consommation).
    - Pas d’IA lourde dans le MVP ; évolutivité vers TensorFlow Lite si performances garanties (Phase 2+).
  - **Priorité** : P3.

#### 3.4 Epic 4 : Budget Basique

**Objectif** : Aider l’utilisateur à budgétiser ses ravitaillements ménagers.

- **US-4.1 (Must)** : En tant qu’utilisatrice, je veux estimer mon budget mensuel pour les consommables, pour mieux gérer mes dépenses.

  - **Critères d’acceptation** :
    - Calcul basé sur les articles inventoriés et leurs fréquences d’achat.
    - Prix moyens en FCFA (ex. : savon 500 FCFA, détergent 2 000 FCFA).
    - Ajustement manuel des prix par l’utilisateur.
    - Validation en &lt;30 secondes via tests terrain.
  - **Priorité** : P1.

- **US-4.2 (Should)** : En tant qu’utilisatrice, je veux des conseils budgétaires simples, pour optimiser mes dépenses.

  - **Critères d’acceptation** :
    - Suggestions basées sur règles métier (ex. : acheter en gros pour économiser).
    - Affichage dans le dashboard (ex. : "Économisez 10% en achetant 2 savons").
  - **Priorité** : P2.

- **US-4.3 (Could)** : En tant qu’utilisatrice premium, je veux des analyses avancées de mes dépenses, pour un suivi détaillé.

  - **Critères d’acceptation** :
    - Graphiques simples (ex. : dépenses par catégorie/mois) et guidees (intuitive guideliner).
    - Synchronisation cloud pour historique (Phase 2).
  - **Priorité** : P3.

#### 3.5 Epic 5 : Settings & Privacy

**Objectif** : Garantir une configuration simple et un contrôle total sur les données.

- **US-5.1 (Must)** : En tant qu’utilisatrice, je veux gérer mes préférences (langue, notifications, confidentialité), pour personnaliser mon expérience.

  - **Critères d’acceptation** :
    - Options : langue, fréquence des notifications, mode hors ligne.
    - Consentement explicite pour toute synchronisation (premium).
    - Validation en &lt;30 secondes via tests terrain.
  - **Priorité** : P1.

- **US-5.2 (Must)** : En tant qu’utilisatrice, je veux sauvegarder et restaurer mes données localement, pour sécuriser mon inventaire.

  - **Critères d’acceptation** :
    - Sauvegarde manuelle sur stockage local (SQLite).
    - Restauration en cas de réinstallation.
    - Cryptage AES-256 des données.
  - **Priorité** : P1.

- **US-5.3 (Could)** : En tant qu’utilisatrice premium, je veux un support prioritaire via WhatsApp, pour résoudre mes problèmes rapidement.

  - **Critères d’acceptation** :
    - Canal dédié pour utilisateurs premium (Phase 2).
    - Réponse en &lt;24h.
  - **Priorité** : P3.

#### 3.6 Évolutions Futures (V2+)

- **Alimentation (V2, Mois 7+)** : Gestion des produits alimentaires (ex. : riz, huile), avec recommandations basées sur le profil foyer et fréquences d’achat.
- **Prédictions avancées (Phase 3)** : Introduction de modèles ML légers (ex. : TensorFlow Lite) pour prédictions basées sur habitudes, si performances garanties.
- **Internationalisation (Phase 3)** : Adaptation des prix (CAD, EUR), langues (lingala, langues asiatiques), et catégories pour les marchés Canada, France, Asie.
- **Gamification légère** : Badges ou encouragements pour rétention (ex. : "Bravo, inventaire à jour !"), après validation terrain.


### 4. Exigences Non Fonctionnelles

Les exigences non fonctionnelles garantissent que **NgonNest** est **performante**, **sécurisée**, **accessible**, et **adaptée** aux contraintes du marché camerounais tout en restant évolutive pour les expansions régionales (Afrique centrale) et internationales (Canada, France, Asie). Chaque exigence est conçue pour répondre au critère : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette application sans frustration ?"**

#### 4.1 Performance

- **NF-4.1.1** : L’application doit avoir un **temps de chargement initial** inférieur à **2 secondes** sur un appareil milieu de gamme (ex. : Samsung Galaxy A12, 2 Go RAM) en mode hors ligne.
  - **Mesure** : Test sur 5 appareils Android/iOS représentatifs, avec connexion 3G/4G et sans connexion.
  - **Priorité** : Must (P1).

- **NF-4.1.2** : La consommation énergétique doit être minimale, avec un impact de **&lt;1% de batterie par jour** en usage standard (ex. : 5 consultations, 3 ajouts d’articles, 1 notification).
  - **Mesure** : Tests sur appareils à faible capacité, avec suivi via outils de profiling (ex. : Android Battery Historian).
  - **Priorité** : Must (P1).

- **NF-4.1.3** : Les opérations critiques (ajout d’article, affichage des alertes) doivent s’exécuter en **&lt;1 seconde** sur des appareils à 2 Go RAM minimum.
  - **Mesure** : Tests de performance automatisés avec Flutter DevTools.
  - **Priorité** : Must (P1).

- **NF-4.1.4** : L’application doit maintenir des performances stables avec un inventaire de **&lt;100 articles** (MVP) et être extensible à **1 000 articles** (Phase 2) sans dégradation.
  - **Mesure** : Tests de charge avec SQLite (indexation optimisée).
  - **Priorité** : Should (P2).

#### 4.2 Sécurité

- **NF-4.2.1** : Toutes les données locales (profil, inventaire, budget) doivent être stockées avec un **cryptage AES-256** pour garantir la confidentialité.
  - **Mesure** : Audit de sécurité via outils comme OWASP Mobile Security Testing.
  - **Priorité** : Must (P1).

- **NF-4.2.2** : Aucune collecte ni partage de données sans **consentement explicite** de l’utilisateur, avec un mode hors ligne par défaut pour le MVP.
  - **Mesure** : Conformité vérifiée via tests manuels et revue de code.
  - **Priorité** : Must (P1).

- **NF-4.2.3** : La synchronisation cloud optionnelle (Supabase, Phase 2) doit utiliser un **cryptage de bout en bout** et demander un consentement clair avant activation.
  - **Mesure** : Tests de sécurité réseau avec outils comme Wireshark.
  - **Priorité** : Should (P2).

- **NF-4.2.4** : L’application doit être conforme aux réglementations locales (Cameroun) et internationales (ex. : RGPD pour la France) pour les expansions futures.
  - **Mesure** : Audit réglementaire avant lancement international (Phase 3).
  - **Priorité** : Could (P3).

#### 4.3 Accessibilité

- **NF-4.3.1** : L’interface doit être adaptée aux utilisateurs semi-technophiles, avec un **contraste élevé** (ratio ≥ 4.5:1) et une **taille de police minimale de 16px** pour les utilisateurs âgés ou ayant une faible acuité visuelle.
  - **Mesure** : Tests avec outils d’accessibilité (ex. : WAVE, axe DevTools).
  - **Priorité** : Must (P1).

- **NF-4.3.2** : La navigation doit être intuitive, avec un maximum de **3 clics** pour accomplir une tâche critique (ex. : ajouter un article, consulter une alerte).
  - **Mesure** : Tests utilisateurs avec 20 mères de famille (Yaoundé/Douala, dès semaine 3-4).
  - **Priorité** : Must (P1).

- **NF-4.3.3** : L’application doit supporter un **mode vocal** (lecture des alertes, instructions simples) pour les utilisateurs à faible littératie numérique.
  - **Mesure** : Tests terrain avec 5 utilisateurs non technophiles.
  - **Priorité** : Should (P2).

- **NF-4.3.4** : L’interface doit être **multilingue** (français, anglais, ewondo, duala) dès le MVP, avec ajout de langues futures (ex. : lingala, langues asiatiques) en Phase 3.
  - **Mesure** : Validation via tests utilisateurs dans chaque langue.
  - **Priorité** : Must (P1).

- **NF-4.3.5** : L’application doit prévoir un **support pour malvoyants** (ex. : compatibilité avec lecteurs d’écran, commandes vocales avancées) pour les phases futures.
  - **Mesure** : Tests avec outils comme TalkBack (Android) et VoiceOver (iOS) en Phase 2+.
  - **Priorité** : Could (P3).

#### 4.4 Fiabilité

- **NF-4.4.1** : L’application doit avoir un **taux de crash inférieur à 0,5%** sur les appareils cibles (Android 8.0+, iOS 13+).
  - **Mesure** : Suivi via Crashlytics ou outil similaire.
  - **Priorité** : Must (P1).

- **NF-4.4.2** : Les sauvegardes locales doivent être **100% fiables**, avec restauration garantie en cas de réinstallation.
  - **Mesure** : Tests automatisés de sauvegarde/restauration sur 5 appareils.
  - **Priorité** : Must (P1).

#### 4.5 Évolutivité

- **NF-4.5.1** : L’architecture doit supporter une **croissance de 500 à 50 000 utilisateurs** (Cameroun → Afrique centrale) sans refonte majeure.
  - **Mesure** : Tests de charge avec Supabase (500 MB gratuit) et SQLite.
  - **Priorité** : Should (P2).

- **NF-4.5.2** : L’application doit être extensible pour intégrer des fonctionnalités futures (ex. : alimentation en V2, prédictions basées sur règles statistiques ou ML léger en Phase 3) sans dégradation des performances.
  - **Mesure** : Revue d’architecture avec Flutter/Supabase pour points d’extension.
  - **Priorité** : Could (P3).

#### 4.6 Compatibilité

- **NF-4.6.1** : L’application doit être compatible avec **Android 8.0+** et **iOS 13+**, couvrant ~75% des smartphones au Cameroun en 2025.
  - **Mesure** : Tests sur 5 appareils représentatifs (ex. : Samsung A12, iPhone 8).
  - **Priorité** : Must (P1).

- **NF-4.6.2** : L’interface doit être **responsive** pour une future version web/PC (Phase 3, Canada/France).
  - **Mesure** : Tests de rendu avec Flutter Web sur navigateurs standards (Chrome, Safari).
  - **Priorité** : Could (P3).

#### 4.7 Expérience Utilisateur

- **NF-4.7.1** : L’application doit offrir une **expérience fluide** avec un onboarding en **&lt;2 minutes** et des interactions clés (ex. : ajout d’article) en **&lt;15 secondes**.
  - **Mesure** : Tests utilisateurs avec chronométrage (20 mères, Yaoundé/Douala).
  - **Priorité** : Must (P1).

- **NF-4.7.2** : L’interface doit inclure des **tooltips** ou illustrations pour guider les utilisateurs non technophiles (ex. : sliders pour taille de pièce).
  - **Mesure** : Validation via tests terrain (critère "mère de 52 ans").
  - **Priorité** : Should (P2).

### 5. Architecture Technique

L’architecture technique de **NgonNest** est conçue pour être **légère**, **scalable**, et **adaptée** aux contraintes du marché camerounais (connexions instables, appareils à faible capacité : 2 Go RAM minimum), tout en permettant une évolution vers des fonctionnalités avancées (ex. : alimentation en V2, prédictions statistiques, internationalisation). Elle privilégie une approche **offline-first** pour le MVP, avec une synchronisation cloud optionnelle pour les utilisateurs premium. Chaque composant est sélectionné pour respecter le budget initial (10 000 USD hors recrutement) et le critère : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, utiliserait cette application sans frustration ?"**

#### 5.1 Frontend

- **Technologie** : **Flutter** (version stable, ex. : 3.x en 2025) pour un développement cross-platform (Android 8.0+, iOS 13+), garantissant une interface cohérente et performante.
  - **Rationale** : Une seule codebase réduit les coûts de développement/maintenance. Flutter est optimisé pour les appareils à faible capacité et offre une documentation robuste.
  - **Responsivité** : Interface adaptable à différentes tailles d’écran (smartphones, tablettes), avec préparation pour une version web/PC (Phase 3, Canada/France).
  - **Bibliothèques** : Utilisation de packages Flutter standards (ex. : `provider` pour gestion d’état, `sqflite` pour SQLite, `flutter_local_notifications` pour rappels).
  - **Performance** : Temps de rendu des écrans &lt;1 seconde sur appareils milieu de gamme (ex. : Samsung Galaxy A12).
  - **Mesure** : Tests avec Flutter DevTools sur 5 appareils représentatifs.

- **Interfaces clés** (MVP) :
  - Onboarding (2 écrans : profil foyer, préférences).
  - Dashboard (alertes urgentes, actions rapides).
  - Inventaire (liste/grille, ajout/modification).
  - Budget (estimations, conseils simples).
  - Paramètres (langue, notifications, confidentialité).

#### 5.2 Backend Local

- **Technologie** : **SQLite** pour le stockage local des données (profils, inventaire, rappels, budget).
  - **Rationale** : Léger, fiable, et adapté au mode hors ligne (aucune dépendance cloud pour le MVP). Supporte jusqu’à 1 000 articles sans dégradation (Phase 2).
  - **Schéma de base de données** :
    - Table `foyer` : id, nb_personnes, type_logement, nb_pieces, langue.
    - Table `biens_durables` : id, nom, catégorie, piece, date_achat, duree_vie_estimée.
    - Table `consommables` : id, nom, catégorie, piece, frequence_achat, quantite_restante.
    - Table `alertes` : id, article_id, date_notification, message.
    - Table `budget` : id, foyer_id, montant_estime, periode.
    - Table `sauvegardes` : id, date_sauvegarde, contenu (crypté AES-256).
  - **Sécurité** : Cryptage AES-256 des données sensibles (ex. : budget, profil).
  - **Mesure** : Tests de charge (100 articles) et de restauration via scripts automatisés.

#### 5.3 Backend Cloud (Optionnel, Phase 2+)

- **Technologie** : **Supabase** (freemium, 500 MB gratuit, authentification, real-time) pour la synchronisation des profils premium (multi-appareils, partage familial).
  - **Rationale** : Gratuit jusqu’à 50 000 utilisateurs, conforme à la confidentialité (cryptage de bout en bout), et adapté à une synchronisation légère.
  - **Fonctionnalités** :
    - Authentification utilisateur (email/Mobile Money, Phase 2).
    - Synchronisation chiffrée des données foyer/inventaire.
    - Support real-time pour notifications premium (ex. : alertes partagées).
  - **Mesure** : Tests de sécurité réseau (Wireshark) et de charge (50 000 utilisateurs).

#### 5.4 Prédictions et Recommandations

- **Technologie** : **Systèmes experts** basés sur des règles métier simples et calculs statistiques (ex. : moyennes de consommation) pour le MVP et Phase 2.
  - **Rationale** : Léger, sans impact sur les performances (pas de surchauffe ni ralentissement). Évite la complexité de l’IA lourde pour le MVP.
  - **Exemple** : Pour un foyer de 4 personnes avec 2 salles de bain, recommander 6 rouleaux de papier toilette/mois (basé sur moyennes locales).
  - **Évolutivité** : Préparation pour un modèle ML léger (ex. : TensorFlow Lite) en Phase 3, uniquement si les performances sont garanties (&lt;5 MB, sans surchauffe).
  - **Mesure** : Validation des recommandations via tests utilisateurs (20 mères, Yaoundé/Douala).

#### 5.5 Intégrations

- **Notifications** : Intégration avec **flutter_local_notifications** pour des rappels locaux (MVP). Synchronisation avec calendrier natif (Should, Phase 2).
- **Paiements (Premium)** : Intégration avec **Mobile Money** (ex. : MTN, Orange) pour le marché camerounais (Phase 2). Support pour PayPal/Stripe en Phase 3 (Canada/France).
- **Multilinguisme** : Utilisation de `intl` (Flutter) pour gérer français, anglais, ewondo, duala (MVP), avec points d’extension pour lingala, langues asiatiques (Phase 3).
- **Mesure** : Tests d’intégration sur 5 appareils pour chaque fonctionnalité.

#### 5.6 Contraintes Techniques

- **Taille** : Application &lt;25 Mo (MVP), incluant toutes les dépendances (Flutter, SQLite, packages).
- **Compatibilité** : Android 8.0+, iOS 13+, couvrant ~75% des smartphones au Cameroun en 2025.
- **Performance** : Pas de surchauffe ni ralentissement, même sur appareils bas de gamme (2 Go RAM).
- **Maintenance** : Documentation complète (code, schéma DB, APIs) dans un référentiel partagé (ex. : GitHub) pour les équipes futures.
- **Mesure** : Audits via Flutter DevTools, tests de charge, et revue de code.

#### 5.7 Évolutivité

- **MVP (Phase 1)** : Architecture légère (Flutter + SQLite) pour 500 utilisateurs et 100 articles/foyer.
- **Phase 2** : Ajout de Supabase pour synchronisation (50 000 utilisateurs), règles statistiques avancées.
- **Phase 3** : Support web/PC (Flutter Web), modèles ML légers (TensorFlow Lite si performances garanties), internationalisation (langues/devise).
- **Mesure** : Revue d’architecture pour identifier les points d’extension avant chaque phase.

### 6. Plan de Déploiement

Le plan de déploiement structure le développement, les tests, et le lancement de **NgonNest** en phases claires, avec des jalons mesurables pour garantir une livraison de qualité dans les contraintes budgétaires (1 000 USD hors recrutement) et temporelles (MVP en 4 mois). Il s’appuie sur une approche **hyper-locale** pour le Cameroun (Yaoundé/Douala), avec une scalabilité pour l’Afrique centrale (Gabon, RDC) et les marchés internationaux (Canada, France, Asie). Chaque phase inclut des **tests utilisateurs** pour valider l’adoption (critère : "Est-ce que ma mère de 52 ans comprendrait en 30 secondes ?") et des métriques pour mesurer le succès.

#### 6.1 Phases de Développement

- **Phase 1 : MVP (Mois 1-4, Yaoundé/Douala)**

  - **Objectif** : Livrer un MVP fonctionnel focalisé sur la gestion ménagère (onboarding, inventaire, rappels, budget basique) pour 500 utilisateurs.
  - **Activités** :
    - Sprint 1 (Mois 1) : Setup Flutter, SQLite, et UI de base (onboarding, dashboard). Prototype cliquable pour tests terrain dès la semaine 3.
    - Sprint 2 (Mois 2) : Inventaire (ajout, catégorisation) et rappels simples. Tests avec 5 familles locales (feedback hebdomadaire).
    - Sprint 3 (Mois 3) : Budget basique et paramètres (langue, confidentialité). Tests élargis à 20 familles.
    - Sprint 4 (Mois 4) : Polissage, corrections, et préparation au lancement bêta.
  - **Livrables** :
    - Application MVP (Android/iOS, &lt;25 Mo).
    - Documentation technique (schéma DB, code commenté).
    - Rapport de tests terrain (20 utilisateurs, taux de satisfaction &gt;4/5).
  - **Métriques de succès** :
    - Onboarding terminé par 60% des utilisateurs en &lt;2 minutes.
    - Rétention J7 &gt;30% (usage hebdomadaire &gt;2x).
    - Taux de crash &lt;0,5%.
  - **Budget** : 1 000 USD (développement, design, tests).

- **Phase 2 : Validation & Améliorations (Mois 5-12, Cameroun)**

  - **Objectif** : Valider l’adoption (10 000 utilisateurs) et ajouter des fonctionnalités premium (synchronisation, prédictions statistiques).
  - **Activités** :
    - Mois 5-8 : Lancement bêta (500 utilisateurs, Yaoundé/Douala). Campagnes WhatsApp et partenariats épiceries locales (ex. : Mahima).
    - Mois 9-12 : Ajout de la synchronisation Supabase, liste de courses exportable, et recommandations statistiques avancées. Expansion à 10 000 utilisateurs.
  - **Livrables** :
    - Version premium (600 FCFA/mois ou 6k FCFA/an).
    - Rapport de tests utilisateurs (40% d’usage hebdomadaire, 5% de conversion premium).
    - Documentation mise à jour (APIs Supabase, règles statistiques).
  - **Métriques de succès** :
    - 10 000 utilisateurs, 5% premium (25 000 FCFA/mois).
    - Rétention J30 &gt;20%.
    - NPS (Net Promoter Score) &gt;30.

- **Phase 3 : Expansion Régionale & Internationale (Mois 13+, Afrique centrale, Canada, France)**

  - **Objectif** : Atteindre 50 000 utilisateurs (Afrique centrale) et préparer le déploiement international.
  - **Activités** :
    - Adaptation pour Gabon/RDC (langues, devises, produits locaux).
    - Intégration de la gestion alimentaire (V2).
    - Préparation pour Canada/France (Flutter Web, devises CAD/EUR, RGPD).
    - Tests exploratoires en Asie via stores d’applications.
  - **Livrables** :
    - Application V2 (ménage + alimentation).
    - Documentation internationalisation (langues, devises).
    - Rapport de performance (50 000 utilisateurs sans refonte).
  - **Métriques de succès** :
    - 50 000 utilisateurs, 8% premium (130 000 FCFA/mois).
    - Performance stable (&lt;2s chargement, &lt;0,5% crash).
    - Adoption initiale dans 2 pays supplémentaires (ex. : Gabon, Canada).

#### 6.2 Tests

- **Tests unitaires** :

  - Couverture &gt;80% pour les fonctionnalités critiques (onboarding, inventaire, rappels).
  - Outils : Flutter Test, Dart unittest.
  - Fréquence : À chaque sprint (Mois 1-4).

- **Tests d’intégration** :

  - Validation des flux (ex. : ajout article → notification → budget).
  - Outils : Flutter Integration Testing.
  - Fréquence : Fin de sprint 2 et 4.

- **Tests utilisateurs** :

  - Dès la semaine 3 (prototype cliquable) : 5 familles locales (Yaoundé/Douala).
  - Mois 3-4 : 20 mères de famille (critère : "mère de 52 ans en 30 secondes").
  - Mois 5-8 : 500 utilisateurs bêta (feedback via WhatsApp, taux de satisfaction &gt;4/5).
  - **Mesure** : Chronométrage des tâches, enquêtes qualitatives.

- **Tests de performance** :

  - Charge : 100 articles/foyer (MVP), 1 000 articles (Phase 2).
  - Appareils : 5 modèles représentatifs (ex. : Samsung A12, iPhone 8).
  - Outils : Flutter DevTools, Android Battery Historian.

- **Tests de sécurité** :

  - Cryptage AES-256 (données locales).
  - Tests réseau pour Supabase (Phase 2).
  - Outils : OWASP Mobile Security Testing, Wireshark.

#### 6.3 Stratégie de Déploiement

- **Phase 1 (Mois 1-4)** :

  - Lancement bêta local (Yaoundé/Douala) via stores Android/iOS.
  - Distribution : Bouche-à-oreille, groupes WhatsApp, partenariats épiceries (ex. : SantaLucia).
  - Budget marketing : 20 000 FCFA (flyers, promotions locales).

- **Phase 2 (Mois 5-12)** :

  - Expansion Cameroun : Ads géolocalisées (WhatsApp, Facebook), partenariats supermarchés.
  - Acquisition : 10 000 utilisateurs via parrainage et influenceurs locaux.
  - Support : Canal WhatsApp pour feedback (réponse &lt;24h pour premium).

- **Phase 3 (Mois 13+)** :

  - Afrique centrale : Adaptation pour Gabon/RDC (langues, produits locaux).
  - International : Lancement Canada/France via diaspora camerounaise, stores d’applications.
  - Tests exploratoires Asie (ex. : validation via Google Play/App Store).

#### 6.4 Validation Continue

- **Tests terrain** : Hebdomadaires dès la semaine 3 (5 familles), puis mensuels (20-500 utilisateurs).
- **Feedback utilisateur** : Collecte via WhatsApp et enquêtes in-app (questions simples, ex. : "L’app est-elle facile à utiliser ?").
- **Métriques suivies** :
  - Onboarding : 60% complété en &lt;2 minutes.
  - Rétention : J7 &gt;30%, J30 &gt;20%.
  - Conversion premium : 5% (Mois 4-6), 8% (Mois 13+).
  - NPS : &gt;30 (Phase 2).

#### 6.5 Documentation

- **Livrables** :
  - Documentation technique (code, schéma DB, APIs) dans un référentiel partagé (ex. : GitHub).
  - Guide utilisateur (PDF, in-app) en français, anglais, ewondo, duala.
  - Rapports de tests (unitaires, utilisateurs, performance).
- **Maintien** : Mise à jour à chaque sprint, accessible à toutes les équipes (SSOT).

### 7. Budget Prévisionnel

Le budget prévisionnel détaille les coûts pour le développement, le design, les tests, l’hébergement Supabase, les frais de déploiement sur les stores (Google Play, App Store), et le marketing de **NgonNest**, en respectant les contraintes financières initiales (1 000 USD hors recrutement, 20 000 FCFA pour le marketing). Les estimations tiennent compte des besoins du marché camerounais et de l’évolutivité pour les phases futures (Afrique centrale, Canada, France, Asie). Les coûts sont basés sur des ressources locales (Cameroun), des outils freemium (Flutter, Supabase plan gratuit pour le MVP), et les frais des stores. Les coûts de recrutement sont exclus mais mentionnés pour référence.

#### 7.1 Budget MVP (Phase 1, Mois 1-4)

- **Développement** :

  - **Coût** : 600 USD.
  - **Détail** : Configuration Flutter, SQLite, fonctionnalités MVP (onboarding, inventaire, rappels, budget). Inclut tests unitaires/intégration et documentation technique.
  - **Rationale** : Estimation basée sur 4 mois de travail à temps partiel pour 1 développeur (taux local ajusté, hors recrutement).

- **Design UX/UI** :

  - **Coût** : 250 USD.
  - **Détail** : Conception d’interfaces simples (onboarding, dashboard, inventaire, budget, paramètres) avec wireframes, illustrations, et tooltips. Tests utilisateurs inclus (20 mères, Yaoundé/Douala).
  - **Rationale** : Designer local freelance, 4 mois de travail partiel.

- **Tests** :

  - **Coût** : 100 USD.
  - **Détail** : Tests unitaires (&gt;80% couverture), intégration, performance (Flutter DevTools), et sécurité (OWASP). Tests terrain avec 5-20 familles (semaine 3-4).
  - **Rationale** : Outils gratuits (Flutter Test) et tests utilisateurs locaux à faible coût.

- **Hébergement Supabase** :

  - **Coût** : 0 USD.
  - **Détail** : Plan gratuit Supabase (500 MB stockage, 10 000 MAUs, 2 projets gratuits) pour le MVP, car la synchronisation cloud est optionnelle (Phase 2+). Aucun coût pour le mode hors ligne (SQLite).
  - **Rationale** : Le plan gratuit couvre les besoins du MVP (500 utilisateurs, données minimales).[](https://uibakery.io/blog/supabase-pricing)

- **Frais de déploiement sur les stores** :

  - **Coût** : 124 USD.
  - **Détail** :
    - **Google Play** : 25 USD (frais unique, compte développeur).
    - **App Store** : 99 USD (frais annuel, Apple Developer Program).
  - **Rationale** : Frais standards pour publier sur Google Play et App Store. Le coût annuel Apple est provisionné pour le MVP (Mois 1-4).[](https://www.digittrix.com/blogs/how-much-does-it-cost-to-publish-your-app-on-the-application-store)[](https://www.swing2app.com/blog/how-much-does-it-cost-to-publish-an-app-on-the-app-store/)

- **Marketing initial** :

  - **Coût** : 20 000 FCFA (\~30 USD).
  - **Détail** : Flyers, promotions WhatsApp, partenariats épiceries (ex. : SantaLucia, Mahima) pour 500 utilisateurs bêta.
  - **Rationale** : Approche hyper-locale pour minimiser les coûts (bouche-à-oreille, groupes communautaires).

- **Total Phase 1** : 1 074 USD + 20 000 FCFA (\~1 104 USD).

#### 7.2 Budget Phase 2 (Mois 5-12, Validation & Améliorations)

- **Développement additionnel** :

  - **Coût estimé** : 500 USD.
  - **Détail** : Ajout de la synchronisation Supabase, liste de courses exportable, recommandations statistiques avancées. Maintenance du MVP.
  - **Rationale** : 8 mois de travail partiel pour 1 développeur.

- **Design UX/UI additionnel** :

  - **Coût estimé** : 150 USD.
  - **Détail** : Mise à jour des interfaces pour fonctionnalités premium (synchronisation, analyses simples). Tests utilisateurs élargis (500 utilisateurs).
  - **Rationale** : Designer local, 4 mois partiels.

- **Tests** :

  - **Coût estimé** : 100 USD.
  - **Détail** : Tests de charge (10 000 utilisateurs), sécurité réseau (Supabase), et utilisateurs bêta (40% usage hebdomadaire).
  - **Rationale** : Outils gratuits et tests locaux.

- **Hébergement Supabase** :

  - **Coût estimé** : 200 USD.
  - **Détail** : Plan Pro Supabase (25 USD/mois, inclut 10 USD de crédits compute pour 1 instance Micro). Estimation pour 8 mois, avec 10 000 utilisateurs et ~1 GB stockage (surcoûts minimes pour bande passante/stockage supplémentaires).
  - **Rationale** : Le plan Pro est nécessaire pour la synchronisation cloud et les utilisateurs premium. Spend Cap activé pour éviter les surcoûts imprévus.[](https://www.supadex.app/blog/supabase-pricing-what-you-really-need-to-know)

- **Frais de déploiement sur les stores** :

  - **Coût estimé** : 0 USD.
  - **Détail** : Aucun frais supplémentaire (Google Play : frais unique déjà payé ; App Store : frais annuel couvert dans Phase 1 pour la première année).
  - **Rationale** : Les comptes développeurs sont déjà actifs.

- **Marketing** :

  - **Coût estimé** : 5 000 FCFA (\~75 USD).
  - **Détail** : Ads géolocalisées (WhatsApp, Facebook), partenariats supermarchés, programme de parrainage pour 10 000 utilisateurs.
  - **Rationale** : Croissance organique via influenceurs locaux.

- **Total Phase 2** : \~1 025 USD + 5 000 FCFA (\~1 033 USD).

#### 7.3 Budget Phase 3 (Mois 13+, Expansion Régionale & Internationale)

- **Développement** :

  - **Coût estimé** : 1 000 USD.
  - **Détail** : Gestion alimentaire (V2), Flutter Web, adaptations pour Gabon/RDC (langues, devises), et Canada/France (RGPD, CAD/EUR). Tests exploratoires Asie.
  - **Rationale** : 12 mois de travail partiel, équipe élargie si nécessaire.

- **Design UX/UI** :

  - **Coût estimé** : 300 USD.
  - **Détail** : Interfaces pour alimentation, web, et internationalisation (ex. : lingala, langues asiatiques).
  - **Rationale** : Designer local/international, 6 mois partiels.

- **Tests** :

  - **Coût estimé** : 200 USD.
  - **Détail** : Tests de charge (50 000 utilisateurs), compatibilité web, conformité RGPD.
  - **Rationale** : Outils gratuits + audits externes pour internationalisation.

- **Hébergement Supabase** :

  - **Coût estimé** : 300 USD.
  - **Détail** : Plan Pro Supabase (25 USD/mois) pour 12 mois, avec surcoûts estimés pour 50 000 utilisateurs (~2 GB stockage, bande passante supplémentaire). Possibilité de plan Team (60 USD/mois) si autoscaling ou support avancé requis.
  - **Rationale** : Estimation conservatrice basée sur la croissance prévue. Spend Cap ajustable pour contrôler les coûts.[](https://uibakery.io/blog/supabase-pricing)[](https://www.supadex.app/blog/supabase-pricing-what-you-really-need-to-know)

- **Frais de déploiement sur les stores** :

  - **Coût estimé** : 99 USD.
  - **Détail** : Renouvellement annuel Apple Developer Program (99 USD). Google Play sans frais supplémentaires.
  - **Rationale** : Coût récurrent pour maintenir l’app sur l’App Store.

- **Marketing** :

  - **Coût estimé** : 100 USD.
  - **Détail** : Campagnes via diaspora (Canada/France), ads stores d’applications, partenariats régionaux (Gabon, RDC).
  - **Rationale** : Croissance organique + budget publicitaire modéré.

- **Total Phase 3** : \~1 999 USD.

#### 7.4 Coûts de Recrutement (Hors Budget Initial, pour Référence)

- **Développeur Flutter** : \~1 500 USD (6 mois, taux local, hors budget initial).
- **Designer UX/UI** : \~500 USD (4 mois, taux local, hors budget initial).
- **Rationale** : Basé sur estimations locales (Cameroun) pour freelances qualifiés, comme indiqué dans Gr_expert_Feedreport.pdf.

#### 7.5 Projections de Revenus

- **Phase 1 (Mois 1-4)** :

  - Utilisateurs : 500, 0% premium (bêta gratuite).
  - Revenu : 0 FCFA.

- **Phase 2 (Mois 5-12)** :

  - Utilisateurs : 10 000, 5% premium (600 FCFA/mois).
  - Revenu estimé : \~25 000 FCFA/mois (\~300 000 FCFA/an, \~500 USD).

- **Phase 3 (Mois 13+)** :

  - Utilisateurs : 50 000, 8% premium.
  - Revenu estimé : \~130 000 FCFA/mois (\~1 560 000 FCFA/an, \~2 600 USD).

- **Rationale** : Projections réalistes basées sur ngonnest_analysis.md, ajustées pour le pouvoir d’achat camerounais et la conversion freemium.

#### 7.6 Hypothèses et Contraintes

- **Hypothèses** :
  - Taux de change : 1 USD = \~600 FCFA (2025).
  - Supabase plan gratuit suffisant pour MVP (500 utilisateurs, &lt;500 MB).
  - Plan Pro Supabase (25 USD/mois) couvre Phase 2 et 3 jusqu’à 50 000 utilisateurs avec surcoûts minimes.
  - Croissance organique via bouche-à-oreille réduit les coûts marketing.
- **Contraintes** :
  - Budget initial limité à 1 000 USD (hors recrutement) + 20 000 FCFA marketing.
  - Dépendance à des freelances locaux pour respecter les coûts.
  - Frais récurrents App Store (99 USD/an) à provisionner.
  - Adoption lente possible (public semi-technophile).

#### 7.7 Validation Budgétaire

- **Revue trimestrielle** : Analyse des dépenses réelles vs prévues à la fin de chaque sprint (Mois 1-4) et phase (Mois 5-12, 13+).
- **Ajustements** : Redéfinition des priorités si dépassement (ex. : report des fonctionnalités Should/Could).
- **Documentation** : Registre des coûts dans un référentiel partagé (ex. : Google Sheets) pour transparence (SSOT).

### 8. Risques et Mitigation

Cette section identifie les **risques clés** associés au développement, au déploiement, et à l’adoption de **NgonNest**, ainsi que les **stratégies de mitigation** pour garantir le succès du MVP (Phase 1, Mois 1-4), de la validation (Phase 2, Mois 5-12), et de l’expansion (Phase 3, Mois 13+). Les risques sont classés par **catégorie** (technique, marché, budgétaire, réglementaire, culturel) et évalués selon leur **probabilité** (faible/moyenne/élevée) et **impact** (faible/moyen/élevé). Chaque stratégie respecte les contraintes budgétaires (1 000 USD + 20 000 FCFA pour le MVP) et le critère d’adoption ("mère de 52 ans en 30 secondes").

#### 8.1 Risques Techniques

- **R-8.1.1 : Dépassement des performances sur appareils bas de gamme**

  - **Description** : L’application pourrait dépasser les seuils de performance (&lt;2s chargement, &lt;1% batterie/jour) sur des appareils à 2 Go RAM (ex. : Samsung Galaxy A12).
  - **Probabilité** : Moyenne.
  - **Impact** : Élevé (frustration des utilisateurs semi-technophiles).
  - **Mitigation** :
    - Utiliser Flutter DevTools pour optimiser le rendu UI et SQLite pour des requêtes légères dès le sprint 1.
    - Tests sur 5 appareils bas de gamme dès la semaine 3 (prototype cliquable).
    - Prioriser les fonctionnalités Must (P1) et reporter Should/Could si nécessaire.
  - **Mesure** : Tests de performance (temps de chargement &lt;2s, &lt;1s pour opérations critiques).

- **R-8.1.2 : Problèmes de fiabilité des sauvegardes locales**

  - **Description** : Les sauvegardes SQLite (cryptées AES-256) pourraient échouer, entraînant une perte de données utilisateur.
  - **Probabilité** : Faible.
  - **Impact** : Élevé (perte de confiance).
  - **Mitigation** :
    - Implémenter des tests automatisés de sauvegarde/restauration dès le sprint 2.
    - Fournir un guide utilisateur clair (in-app, PDF) pour sauvegardes manuelles.
    - Monitorer les crashs via Crashlytics (taux &lt;0,5%).
  - **Mesure** : 100% de réussite des tests de restauration sur 5 appareils.

- **R-8.1.3 : Complexité d’intégration Supabase (Phase 2)**

  - **Description** : La synchronisation cloud (Supabase) pourrait introduire des erreurs ou des coûts imprévus pour 10 000 utilisateurs.
  - **Probabilité** : Moyenne.
  - **Impact** : Moyen (affecte les utilisateurs premium).
  - **Mitigation** :
    - Utiliser le plan gratuit Supabase pour tests initiaux (MVP, 500 utilisateurs).
    - Activer le Spend Cap sur le plan Pro (25 USD/mois) pour limiter les surcoûts.
    - Effectuer des tests de sécurité réseau (Wireshark) avant le lancement de la synchronisation (Mois 5).
  - **Mesure** : Tests de charge réussis pour 10 000 utilisateurs (Phase 2).

#### 8.2 Risques de Marché

- **R-8.2.1 : Faible adoption par le public cible**

  - **Description** : Les mères urbaines (25-45 ans) et jeunes actifs pourraient trouver l’application trop complexe ou non essentielle.
  - **Probabilité** : Moyenne.
  - **Impact** : Élevé (échec du MVP).
  - **Mitigation** :
    - Tests terrain dès la semaine 3 avec 5 familles, puis 20 mères (Mois 3-4), pour valider la simplicité (critère "mère de 52 ans").
    - Onboarding intuitif (&lt;2 minutes) avec tooltips/illustrations.
    - Campagnes hyper-locales (WhatsApp, épiceries) pour 500 utilisateurs bêta.
  - **Mesure** : Rétention J7 &gt;30%, onboarding complété par 60% des utilisateurs en &lt;2 minutes.

- **R-8.2.2 : Faible conversion au modèle premium**

  - **Description** : Moins de 5% des utilisateurs pourraient souscrire à la version premium (600 FCFA/mois) en Phase 2.
  - **Probabilité** : Moyenne.
  - **Impact** : Moyen (revenus limités).
  - **Mitigation** :
    - Offrir une période d’essai gratuite (30 jours) pour les fonctionnalités premium (synchronisation, analyses).
    - Promouvoir via partenariats locaux (ex. : supermarchés) et influenceurs.
    - Collecter feedback utilisateur via WhatsApp pour ajuster les fonctionnalités premium.
  - **Mesure** : Conversion premium &gt;5% (Mois 5-12), NPS &gt;30.

#### 8.3 Risques Budgétaires

- **R-8.3.1 : Dépassement du budget initial**

  - **Description** : Les coûts pourraient dépasser 1 000 USD + 20 000 FCFA pour le MVP, notamment pour le développement ou les frais de stores.
  - **Probabilité** : Moyenne.
  - **Impact** : Élevé (risque d’arrêt du projet).
  - **Mitigation** :
    - Suivi hebdomadaire des dépenses via Google Sheets (SSOT).
    - Prioriser les fonctionnalités Must (P1) et reporter Should/Could si nécessaire.
    - Utiliser des outils freemium (Flutter, Supabase plan gratuit) pour minimiser les coûts.
  - **Mesure** : Revue budgétaire à la fin de chaque sprint (Mois 1-4).

- **R-8.3.2 : Surcoûts Supabase en Phase 2**

  - **Description** : L’hébergement Supabase pourrait dépasser 200 USD (plan Pro) pour 10 000 utilisateurs si la bande passante ou le stockage augmente.
  - **Probabilité** : Faible.
  - **Impact** : Moyen (impact sur la rentabilité).
  - **Mitigation** :
    - Activer le Spend Cap sur Supabase pour limiter les surcoûts.
    - Optimiser les données synchronisées (ex. : deltas uniquement).
    - Monitorer l’usage via Supabase Analytics dès le Mois 5.
  - **Mesure** : Coûts mensuels &lt;25 USD + 10 USD crédits compute.

#### 8.4 Risques Réglementaires

- **R-8.4.1 : Non-conformité RGPD pour l’expansion internationale**
  - **Description** : L’application pourrait ne pas respecter le RGPD lors du déploiement en France (Phase 3).
  - **Probabilité** : Faible.
  - **Impact** : Élevé (amendes, interdiction).
  - **Mitigation** :
    - Implémenter un consentement explicite pour la synchronisation dès le MVP.
    - Effectuer un audit RGPD (via consultant externe) avant le lancement en France (Mois 13).
    - Utiliser Supabase (conforme RGPD) pour le cloud.
  - **Mesure** : Audit réglementaire réussi avant Phase 3.

#### 8.5 Risques Culturels

- **R-8.5.1 : Non-adaptation aux réalités locales**

  - **Description** : Les catégories d’articles ou l’interface pourraient ne pas convenir aux réalités camerounaises (ex. : savon artisanal, balais traditionnels).
  - **Probabilité** : Moyenne.
  - **Impact** : Moyen (adoption réduite).
  - **Mitigation** :
    - Co-construire les catégories avec 20 familles locales dès le sprint 1.
    - Inclure des produits locaux dans l’inventaire (ex. : savon artisanal, huile de palme).
    - Valider l’interface via tests terrain (semaine 3-4).
  - **Mesure** : Taux de satisfaction &gt;4/5 lors des tests utilisateurs.

- **R-8.5.2 : Difficultés d’adaptation internationale**

  - **Description** : L’interface/langues pourraient ne pas convenir aux marchés Canada/France/Asie en Phase 3.
  - **Probabilité** : Moyenne.
  - **Impact** : Moyen (adoption limitée).
  - **Mitigation** :
    - Préparer des points d’extension pour langues/devise dès le MVP (ex. : `intl` pour multilinguisme).
    - Tester avec la diaspora camerounaise (Canada/France) dès la Phase 2.
    - Explorer les besoins asiatiques via stores (Mois 13+).
  - **Mesure** : Adoption initiale dans 2 pays (ex. : Gabon, Canada) en Phase 3.

#### 8.6 Documentation des Risques

- **Registre des risques** : Maintenu dans un référentiel partagé (ex. : Google Sheets) avec suivi de probabilité, impact, et statut de mitigation.
- **Revue** : Hebdomadaire (sprints MVP), puis mensuelle (Phases 2-3).
- **Escalade** : Alertes immédiates pour risques à impact élevé (ex. : dépassement budgétaire) via canal WhatsApp dédié.
### 9. Gouvernance des Données

La gouvernance des données définit les politiques et processus pour gérer les **données utilisateur** de **NgonNest** (profil foyer, inventaire, rappels, budget) avec un focus sur la **confidentialité**, la **sécurité**, et la **qualité**, tout en respectant les contraintes du marché camerounais (connexions instables, méfiance envers la collecte de données) et les exigences internationales (ex. : RGPD pour la France). Elle s’appuie sur une approche **offline-first** pour le MVP (données stockées localement via SQLite) et une synchronisation cloud optionnelle (Supabase, Phase 2+). Toutes les politiques sont conçues pour être **simples** et **transparentes**, alignées sur le critère : **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait la gestion de ses données ?"**

#### 9.1 Classification des Données

- **Données utilisateur** :

  - **Type** : Profil foyer (nb_personnes, type_logement, nb_pieces, langue), inventaire (biens durables/consommables), rappels, budget.
  - **Sensibilité** : Sensible (données personnelles liées au foyer et aux finances).
  - **Stockage** : Local (SQLite, crypté AES-256) pour le MVP. Cloud (Supabase, cryptage de bout en bout) pour utilisateurs premium (Phase 2+).
  - **Rationale** : Minimiser les risques de fuite de données en priorisant le stockage local.

- **Données techniques** :

  - **Type** : Logs d’utilisation anonymisés (ex. : crash reports via Crashlytics, métriques de performance).
  - **Sensibilité** : Non sensible (aucune information identifiable).
  - **Stockage** : Local pour le MVP, cloud anonymisé (Phase 2+).
  - **Rationale** : Améliorer l’application sans compromettre la confidentialité.

- **Données premium (Phase 2+)** :

  - **Type** : Données synchronisées (profil, inventaire partagé).
  - **Sensibilité** : Sensible (nécessite consentement explicite).
  - **Stockage** : Supabase avec cryptage de bout en bout.
  - **Rationale** : Fonctionnalité premium avec transparence pour l’utilisateur.

#### 9.2 Droits d’Accès

- **Utilisateur** :

  - Accès complet à ses données (profil, inventaire, rappels, budget) via l’application.
  - Contrôle total : modification, suppression, sauvegarde/restauration locale.
  - Consentement explicite requis pour la synchronisation cloud (Phase 2).
  - **Mesure** : Interface de paramètres claire, validée par tests terrain (20 mères, Mois 3-4).

- **Équipe de développement** :

  - Accès restreint aux logs anonymisés pour maintenance (ex. : Crashlytics).
  - Aucun accès aux données sensibles sauf autorisation explicite (ex. : support premium).
  - **Mesure** : Audit de sécurité via OWASP Mobile Security Testing.

- **Tiers** :

  - Aucun accès aux données utilisateur (locales ou cloud) sans consentement.
  - Partenariats (ex. : épiceries) limités à des métadonnées anonymisées (ex. : tendances d’achat générales, Phase 3).
  - **Mesure** : Contrats clairs avec les tiers, revue juridique avant Phase 3.

#### 9.3 Qualité des Données

- **Exactitude** :

  - Validation des saisies utilisateur (ex. : champs obligatoires pour profil foyer, fréquences d’achat réalistes).
  - Suggestions basées sur règles statistiques (ex. : 6 rouleaux de papier toilette/mois pour 4 personnes) pour éviter les erreurs.
  - **Mesure** : Tests utilisateurs (20 mères, Mois 3-4) pour valider la pertinence des suggestions.

- **Cohérence** :

  - Synchronisation des données locales/cloud (Phase 2) via deltas pour éviter les conflits.
  - Format standardisé (ex. : dates en ISO 8601, devises en FCFA/CAD/EUR).
  - **Mesure** : Tests d’intégration pour synchronisation (Mois 5).

- **Complétude** :

  - Données minimales requises pour le MVP (ex. : profil foyer, 1 article minimum).
  - Champs optionnels pour flexibilité (ex. : notes personnalisées sur articles).
  - **Mesure** : Onboarding complété par 60% des utilisateurs en &lt;2 minutes.

#### 9.4 Confidentialité

- **Stockage local (MVP)** :

  - Toutes les données stockées via SQLite avec cryptage AES-256.
  - Sauvegardes manuelles cryptées sur le stockage de l’appareil.
  - **Mesure** : Tests de sécurité (OWASP) pour garantir l’intégrité des données.

- **Synchronisation cloud (Phase 2+)** :

  - Consentement explicite via pop-up clair avant activation (ex. : "Autoriser la synchronisation pour partager vos données avec votre famille ?").
  - Cryptage de bout en bout via Supabase.
  - **Mesure** : Tests réseau (Wireshark) pour vérifier l’absence de fuites.

- **Transparence** :

  - Politique de confidentialité (in-app, PDF) en langage simple (français, anglais, ewondo, duala).
  - Explication des données collectées (ex. : "Nous stockons votre inventaire localement pour protéger votre vie privée").
  - **Mesure** : Validation via tests terrain (critère "mère de 52 ans comprend en 30 secondes").

#### 9.5 Conformité Réglementaire

- **Cameroun (MVP)** :

  - Respect des lois locales sur la protection des données (ex. : aucune collecte non essentielle).
  - **Mesure** : Revue juridique avant lancement (Mois 4).

- **International (Phase 3)** :

  - Conformité RGPD pour la France (ex. : droit à l’oubli, consentement explicite).
  - Conformité aux lois canadiennes (PIPEDA) pour le Canada.
  - **Mesure** : Audit externe RGPD/PIPEDA avant lancement international (Mois 13).

#### 9.6 Documentation et Suivi

- **Data Dictionary** :

  - Description de chaque entité (foyer, biens_durables, consommables, alertes, budget) avec type, sensibilité, et usage.
  - Stocké dans un référentiel partagé (ex. : Google Docs, SSOT).
  - **Mesure** : Mise à jour à chaque sprint (Mois 1-4).

- **Matrice des droits d’accès** :

  - Liste des rôles (utilisateur, développeur, tiers) avec niveaux d’accès.
  - Stockée dans le référentiel partagé.
  - **Mesure** : Revue avant chaque phase (Mois 4, 12, 13+).

- **Registre de conformité** :

  - Suivi des audits (sécurité, RGPD) et des consentements utilisateurs.
  - **Mesure** : Audit trimestriel (Mois 1-4, puis Phase 2-3).

### 10. Plan de Qualité

Le plan de qualité définit les processus, métriques, et tests pour garantir que **NgonNest** répond aux attentes des utilisateurs (mères urbaines, jeunes actifs) en termes de **fonctionnalités**, **performance**, **accessibilité**, et **expérience utilisateur**. Il s’appuie sur une approche **user-centric** pour le MVP (Phase 1, Mois 1-4), avec des validations continues pour les phases futures (Phase 2 : validation, Phase 3 : expansion). Un **bot Telegram** semi-intelligent est intégré pour collecter les retours utilisateurs et créer des issues sur GitHub, renforçant la qualité et l’engagement. Chaque processus respecte les contraintes budgétaires (1 000 USD + 20 000 FCFA) et le critère **"Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait et utiliserait cette application sans frustration ?"**. Les métriques sont mesurables et alignées sur les objectifs d’adoption (rétention J7 &gt;30%, NPS &gt;30).

#### 10.1 Définition de Done (DoD)

Chaque user story (voir section 3) doit répondre aux critères suivants avant d’être considérée comme terminée :

- **Fonctionnalité complète** : Implémentée selon les critères d’acceptation (ex. : ajout d’article en &lt;15 secondes).
- **Testée** : Tests unitaires (&gt;80% couverture) et tests d’intégration validés.
- **Performante** : Temps de réponse &lt;1 seconde pour les opérations critiques, &lt;2 secondes pour le chargement initial (appareils 2 Go RAM).
- **Accessible** : Conforme aux exigences d’accessibilité (contraste ≥4.5:1, police ≥16px).
- **Validée par les utilisateurs** : Testée par au moins 5 utilisateurs représentatifs (mères de 25-45 ans, Yaoundé/Douala) avec un taux de satisfaction &gt;4/5.
- **Documentée** : Code commenté, mise à jour dans le référentiel partagé (ex. : GitHub, SSOT).
- **Mesure** : Revue à la fin de chaque sprint (Mois 1-4) par le Dev Lead.

#### 10.2 Tests de Qualité

- **Tests unitaires** :
  - **Objectif** : Vérifier chaque composant (ex. : ajout d’article, calcul budget, bot Telegram) individuellement.
  - **Outils** : Flutter Test, Dart unittest, tests Python/Node.js pour le bot Telegram.
  - **Couverture** : &gt;80% pour les fonctionnalités critiques (onboarding, inventaire, rappels, bot).
  - **Fréquence** : À chaque sprint (Mois 1-4).
  - **Mesure** : Rapport de couverture via CI/CD (ex. : GitHub Actions).

- **Tests d’intégration** :
  - **Objectif** : Valider les flux complets (ex. : saisie profil → ajout article → notification → budget ; feedback via bot Telegram → issue GitHub).
  - **Outils** : Flutter Integration Testing, tests manuels pour le bot Telegram.
  - **Fréquence** : Fin de sprint 2 et 4 (Mois 2, 4).
  - **Mesure** : 100% des flux critiques fonctionnels sans erreurs.

- **Tests utilisateurs** :
  - **Objectif** : Garantir l’intuitivité et l’adoption (critère "mère de 52 ans en 30 secondes").
  - **Processus** :
    - Semaine 3 : Prototype cliquable testé par 5 familles (Yaoundé/Douala).
    - Mois 3-4 : Tests avec 20 mères (25-45 ans) pour valider onboarding (&lt;2 min), ajout d’article (&lt;15s), navigation (&lt;3 clics), et interaction avec le bot Telegram.
    - Mois 5-8 (Phase 2) : Tests bêta avec 500 utilisateurs (40% usage hebdomadaire).
  - **Mesure** : Taux de satisfaction &gt;4/5, onboarding complété par 60% en &lt;2 min.

- **Tests de performance** :
  - **Objectif** : Vérifier les seuils (chargement &lt;2s, opérations &lt;1s, batterie &lt;1%/jour).
  - **Outils** : Flutter DevTools, Android Battery Historian.
  - **Appareils** : 5 modèles représentatifs (ex. : Samsung A12, iPhone 8).
  - **Fréquence** : Fin de sprint 2, 4 (Mois 2, 4) et Phase 2 (Mois 5-12).
  - **Mesure** : Conformité aux seuils de performance sur 100% des appareils testés.

- **Tests de sécurité** :
  - **Objectif** : Garantir le cryptage AES-256 (local), l’absence de fuites (cloud, Phase 2), et la sécurité du bot Telegram (ex. : protection contre les abus).
  - **Outils** : OWASP Mobile Security Testing, Wireshark (Phase 2), tests manuels pour le bot.
  - **Fréquence** : Mois 4 (MVP) et Mois 5 (Supabase, bot Telegram).
  - **Mesure** : Aucun problème critique détecté lors des audits.

#### 10.3 Métriques de Qualité

- **Métriques techniques** :
  - **Taux de crash** : &lt;0,5% sur Android 8.0+ et iOS 13+.
  - **Temps de chargement** : &lt;2 secondes (appareils 2 Go RAM).
  - **Consommation batterie** : &lt;1% par jour (usage standard : 5 consultations, 3 ajouts, 1 notification).
  - **Réponse du bot Telegram** : &lt;5 secondes pour les commandes simples (ex. : /feedback, /bug).
  - **Outils** : Crashlytics, Flutter DevTools, Telegram Bot Analytics.
  - **Fréquence** : Suivi continu, rapporté hebdomadairement (Mois 1-4).

- **Métriques utilisateur** :
  - **Rétention J7** : &gt;30% (usage &gt;2x/semaine).
  - **Rétention J30** : &gt;20% (Phase 2).
  - **NPS (Net Promoter Score)** : &gt;30 (Phase 2).
  - **Onboarding** : 60% des utilisateurs complètent en &lt;2 minutes.
  - **Usage bot Telegram** : &gt;10% des utilisateurs bêta utilisent le bot pour feedback (Phase 2).
  - **Outils** : Enquêtes in-app, feedback Telegram/WhatsApp, Google Analytics (anonymisé).
  - **Fréquence** : Tests terrain (semaine 3, Mois 3-4), puis mensuel (Phase 2-3).

#### 10.4 Validation Utilisateur

- **Prototype cliquable (Semaine 3)** :
  - Testé avec 5 familles locales pour valider l’intuitivité (onboarding, navigation).
  - **Mesure** : Taux de satisfaction &gt;4/5, feedback qualitatif collecté via WhatsApp.

- **Tests MVP (Mois 3-4)** :
  - 20 mères (25-45 ans, Yaoundé/Douala) testent les fonctionnalités clés (onboarding, inventaire, rappels, budget) et l’interaction avec le bot Telegram (ex. : /feedback "L’app est lente").
  - **Mesure** : 80% des tâches clés réalisées en &lt;30 secondes, taux de satisfaction &gt;4/5.

- **Tests bêta (Mois 5-8, Phase 2)** :
  - 500 utilisateurs bêta, avec focus sur la rétention (40% usage hebdomadaire), la conversion premium (5%), et l’usage du bot Telegram (10% des utilisateurs).
  - **Mesure** : Enquêtes in-app, NPS &gt;30, feedback via Telegram/WhatsApp.

- **Bot Telegram semi-intelligent** :
  - **Objectif** : Collecter les retours utilisateurs (bugs, suggestions) et créer automatiquement des issues sur GitHub.
  - **Fonctionnalités** :
    - Commandes simples : /start, /feedback, /bug, /help.
    - Réponses pré-programmées (ex. : "Merci ! Votre feedback a été envoyé à l’équipe.") avec analyse de base (ex. : détection de mots-clés comme "lent", "crash").
    - Création d’issues GitHub via API (ex. : titre "Bug signalé : app lente", description avec message utilisateur).
  - **Technologie** : BotFather (Telegram), librairie légère (ex. : `python-telegram-bot` ou `node-telegram-bot-api`), hébergé sur instance existante (ex. : Supabase ou serveur local).
  - **Coût** : Absorbé dans le budget développement (600 USD, MVP). Aucun coût d’hébergement supplémentaire.
  - **Mesure** : 90% des feedbacks envoyés via le bot sont transformés en issues GitHub valides (Mois 4).

#### 10.5 Amélioration Continue

- **Feedback utilisateur** :
  - Collecté via enquêtes in-app, WhatsApp, et bot Telegram (ex. : /feedback "Ajoutez plus de produits locaux").
  - Intégré dans la planification des sprints suivants (ex. : ajustement UI, ajout de catégories locales).
  - Issues GitHub créées automatiquement par le bot Telegram pour les bugs/suggestions.
  - **Mesure** : 100% des feedbacks critiques traités avant la fin de chaque sprint.

- **Leçons apprises** :
  - Documentées après chaque sprint (Mois 1-4) dans le référentiel partagé (ex. : Google Docs, SSOT).
  - Exemples : Simplification d’un écran, ajustement des règles statistiques, amélioration du bot Telegram.
  - **Mesure** : Rapport trimestriel des leçons apprises (Mois 4, 12, 13+).

- **Ajustements** :
  - Priorisation des fonctionnalités Must/Should/Could en fonction des résultats des tests et des feedbacks via bot Telegram.
  - Report des fonctionnalités Could si contraintes budgétaires (1 000 USD).
  - **Mesure** : Revue à la fin de chaque sprint par le Dev Lead.

#### 10.6 Documentation de Qualité

- **Rapports de tests** :
  - Tests unitaires, intégration, performance, sécurité, utilisateurs, bot Telegram.
  - Stockés dans le référentiel partagé (ex. : GitHub, Google Docs).
- **Métriques** :
  - Suivi dans un tableau de bord (ex. : Google Sheets) avec colonnes : métrique, cible, résultat, actions correctives.
- **Guide utilisateur** :
  - In-app et PDF (français, anglais, ewondo, duala) pour expliquer les fonctionnalités clés et l’usage du bot Telegram.
  - **Mesure** : Validé par tests terrain (compréhensible en &lt;30 secondes).
## 

### 11. Conclusion et Annexes

#### 11.1 Conclusion

Le cahier des charges de **NgonNest** définit un plan clair et structuré pour développer une application mobile de **gestion ménagère** adaptée au marché camerounais (Yaoundé/Douala), avec une vision d’expansion vers l’Afrique centrale (Gabon, RDC) et les marchés internationaux (Canada, France, Asie). Le MVP (Phase 1, Mois 1-4) se concentre sur des fonctionnalités essentielles : **onboarding**, **inventaire**, **rappels**, et **budget basique**, conçues pour être **simples** et **intuitives** (critère : "Est-ce que ma mère camerounaise de 52 ans, habituée à WhatsApp et Mobile Money, comprendrait en 30 secondes ?").

**Points clés** :

- **Approche user-centric** : Tests terrain dès la semaine 3 (5 familles), puis élargis (20 mères, 500 utilisateurs bêta) pour garantir l’adoption (rétention J7 &gt;30%, NPS &gt;30).
- **Architecture légère** : Flutter et SQLite pour le mode offline-first, avec Supabase pour la synchronisation premium (Phase 2+), assurant performance (&lt;2s chargement) et sécurité (AES-256).
- **Budget maîtrisé** : 1 000 USD + 20 000 FCFA pour le MVP, incluant développement, design, tests, frais de stores (Google Play : 25 USD, App Store : 99 USD), et marketing hyper-local.
- **Évolutivité** : Préparation pour la gestion alimentaire (V2), l’internationalisation (langues, devises), et des prédictions statistiques/ML légères (Phase 3).
- **Qualité** : Tests rigoureux (unitaires, intégration, utilisateurs) et bot Telegram semi-intelligent pour collecter les feedbacks et créer des issues GitHub, renforçant l’amélioration continue.

Ce document constitue une **Single Source of Truth (SSOT)** pour aligner les équipes (Dev Lead, designer, consultants) sur la vision, les contraintes, et les objectifs. Il garantit un produit **scalable**, **sécurisé**, et **centré sur l’utilisateur**, prêt à évoluer d’un MVP local à une solution régionale et internationale.

#### 11.2 Annexes

- **Annexe A : Références Techniques**

  - **Flutter** : Framework cross-platform (https://flutter.dev).
  - **SQLite** : Base de données locale (https://www.sqlite.org).
  - **Supabase** : Backend cloud freemium (https://supabase.com).
  - **Bot Telegram** : Documentation BotFather (https://core.telegram.org/bots), librairie `python-telegram-bot` (https://python-telegram-bot.readthedocs.io).
  - **Outils de test** : Flutter DevTools (https://flutter.dev/docs/development/tools/devtools), OWASP Mobile Security Testing (https://owasp.org/www-project-mobile-security-testing-guide/), Crashlytics (https://firebase.google.com/products/crashlytics).

- **Annexe B : Contacts**

  - **Product Owner** : \[À compléter avec nom/contact PO\].
  - **Dev Lead** : \[À compléter avec nom/contact Dev Lead\].
  - **Designer UX/UI** : \[À compléter avec nom/contact designer\].
  - **Canal de support** : Groupe WhatsApp (MVP) et Telegram (Phase 2) pour feedback utilisateur. Réponse &lt;24h pour premium.
  - **GitHub** : Référentiel projet (ex. : https://github.com/ngonnest) pour code, issues, et documentation.

- **Annexe C : Ressources Complémentaires**

  - **Documents fournis** :
    - Vision initiale (Ngonnest_vision.pdf).
    - Analyse stratégique (ngonnest_analysis.md).
    - Expert Feed Report (Gr_expert_Feedreport.pdf).
    - Analyse critique (Ngonnest_critical_analysis.pdf).
  - **Modèles** :
    - Template de rapport hebdomadaire : Progress vs plan, métriques qualité, feedback utilisateur, blockers, décisions.
    - Matrice des droits d’accès (section 9).
    - Data Dictionary (section 9).
  - **Tests terrain** : Protocole utilisateur (20 mères, Yaoundé/Douala, Mois 3-4).

- **Annexe D : Glossaire**

  - **MVP** : Minimum Viable Product, version initiale avec fonctionnalités essentielles.
  - **SSOT** : Single Source of Truth, référentiel unique pour documentation.
  - **NPS** : Net Promoter Score, mesure de la satisfaction utilisateur.
  - **AES-256** : Standard de cryptage pour données locales.
  - **Supabase** : Plateforme cloud pour synchronisation (Phase 2+).
  - **Bot Telegram** : Outil semi-intelligent pour feedback et création d’issues GitHub.
