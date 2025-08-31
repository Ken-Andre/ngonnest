Journal de décisions – Sprint 1 (Phase 1)

Date : 2025‑08‑30

Contexte

Les wireframes basse fidélité du MVP NgonNest ont été présentés aux parties prenantes (PO, PM, Dev Lead) et à des experts externes. Ce document synthétise leurs retours et les décisions prises pour la suite du projet.

Retours des experts
Points positifs

Prise en compte du contexte local : Les contraintes techniques (mode hors‑ligne, 2 Go RAM), linguistiques (français/ewondo/duala) et culturelles (palette de couleurs inspirée du drapeau, icônes locaux) ont été saluées. Les experts estiment que cette approche est alignée avec la vision du projet et le public cible.

Design mobile‑first et performance : Les choix de navigation en 3 clics, d’économie de données et d’interfaces légères répondent aux bonnes pratiques pour l’Afrique
vanguardngr.com
. L’utilisation d’une police sans empattement lisible et de composants réutilisables facilite l’accessibilité.

Wireframes clairs : Les écrans proposés couvrent toutes les user stories prioritaires du Sprint 1 (onboarding, sélection de langue, création du profil, ajout de consommable, inventaire, tableau de bord). Ils sont jugés fonctionnels et pédagogiques.

Plan de test utilisateur pertinent : Le script prévoyant de mesurer le temps d’onboarding (< 2 min), le taux de réussite (> 70 %) et la compréhension des alertes est jugé réaliste et en phase avec les KPIs (rétention J7 > 30 %, NPS > 30).

Documentation et gouvernance : La proposition de créer un dictionnaire de données et des fiches composants dans un référentiel SSOT a été appréciée.

Points d’amélioration et suggestions

Champs du profil foyer : Le cahier des charges demande explicitement le nombre de personnes, le type de logement (appartement/maison) et la langue. Les champs « Nom du foyer » et « Marché préféré » proposés dans les wireframes doivent être revus ou simplifiés pour rester dans les 2 minutes d’onboarding.

Icônes et exemples : Éviter d’utiliser des pictogrammes ou exemples directement liés à l’alimentation (ex. : riz) pour ne pas élargir le scope du MVP. Privilégier des symboles génériques (maisons, paniers, alarmes).

Accessibilité : Ajouter un marquage clair pour distinguer les champs obligatoires des champs facultatifs (icône ou couleur), afin d’aider les personnes peu alphabétisées. Prévoir des tests spécifiques avec des utilisateurs à faible niveau numérique.

Mode sombre : Proposer un mode sombre optionnel pour améliorer la lisibilité et réduire la consommation d’énergie, surtout sur écrans OLED où le passage en dark mode peut réduire la consommation jusqu’à 42 % à pleine luminosité
forbes.com
.

Gestion du budget et des alertes : Clarifier la hiérarchie des alertes (manque de stock, date de péremption, dépassement de budget). Étudier l’intégration future d’alertes premium (synchronisation cloud) sans perturber l’expérience gratuite.

Synchronisation et sauvegarde : Détailler l’expérience utilisateur en cas de perte de connexion ou lors du retour en ligne. Assurer une transition fluide entre le mode hors‑ligne et le mode synchronisé.

Décisions

Profil foyer : Les champs du formulaire seront ajustés. Le profil comportera :

Nombre de personnes (champ obligatoire).

Type de logement (appartement ou maison).

Langue choisie (français/ewondo/duala).
Les champs « Nom du foyer » et « Marché préféré » seront supprimés ou déplacés en option lors d’une phase ultérieure pour ne pas alourdir l’onboarding.

Icônes et exemples : Les illustrations liées à l’alimentation seront remplacées par des icônes neutres (produits d’entretien, ustensiles domestiques). Les pictogrammes indiqueront clairement les champs obligatoires.

Accessibilité renforcée : Les maquettes haute fidélité intégreront des repères visuels (astérisque, couleur) pour les champs obligatoires. Des tests seront effectués sur des smartphones Android 8.0+ avec 2 Go de RAM.

Mode sombre optionnel : Un thème sombre sera proposé dans les paramètres afin d’améliorer le confort de lecture et d’économiser la batterie sur certains appareils
forbes.com
.

Priorité des alertes : La hiérarchie des alertes sera validée avec les utilisateurs (stock, péremption, budget). Les fonctionnalités premium (synchronisation cloud, prédictions ML) seront notées comme évolutions possibles mais resteront hors scope du Sprint 1.

Documentation : Ce feedback et ces décisions seront ajoutés au decision log du projet sur GitHub. Le dictionnaire de données sera mis à jour pour refléter les nouveaux champs et les règles de validation.

Prochaines étapes

Prototype haute fidélité : Créer les maquettes interactives sur Figma en intégrant ces ajustements. Inclure des micro‑interactions (feedback des boutons, transitions douces) pour tester l’intuitivité.

Validation interne : Organiser une revue avec le PO, le PM et le Dev Lead afin de valider ces maquettes avant le début des tests utilisateurs.

Tests terrain : Finaliser le script d’évaluation et les supports (fiches, questionnaires). Planifier les sessions avec les 5 familles à Yaoundé/Douala.

Mise à jour du SSOT : Ajouter les maquettes haute fidélité et les nouvelles règles dans le référentiel (Google Docs/GitHub). Documenter les leçons apprises pour une meilleure gouvernance.

Synthèse des retours et ajustements clés

Les experts ont validé l’approche mobile‑first, le respect des contraintes locales (offline‑first, 2 Go RAM) et la localisation (français, ewondo, duala).

Ils recommandent d’ajuster le formulaire « Profil foyer » aux champs spécifiés dans le cahier des charges : nombre de personnes, type de logement (appartement/maison) et langue. Les champs « Nom du foyer » et « Marché préféré » seront retirés ou proposés ultérieurement.

L’iconographie doit rester générique (maisons, paniers, alarmes) afin de ne pas élargir le périmètre au domaine alimentaire.

Pour l’accessibilité, nous ajouterons des indications visuelles pour différencier les champs obligatoires et facultatifs, et prévoyons des tests sur des appareils bas de gamme avec des utilisateurs peu familiers du numérique.

Un mode sombre optionnel sera intégré pour améliorer le confort de lecture et économiser la batterie, notamment sur les écrans OLED où l’économie peut atteindre 42 % à luminosité maximale
forbes.com
.

La hiérarchie des alertes (stock faible, péremption, dépassement de budget) sera validée avec les utilisatrices et documentée en prévision des futures options premium (synchronisation cloud, prédictions ML).

Prochaines étapes

Prototype haute fidélité : je démarre la phase 2 en créant les maquettes interactives sur Figma avec les ajustements ci‑dessus. Les micro‑interactions (feedback de bouton, transitions simples) seront incluses pour tester l’intuitivité.

Validation interne : une revue avec le PO, le PM et le Dev Lead permettra de valider ces maquettes avant le début des tests utilisateurs.

Tests terrain : préparation des sessions avec cinq familles à Yaoundé/Douala afin de mesurer le temps d’onboarding, la réussite à l’ajout d’un article et la compréhension des alertes.

Mise à jour documentaire : le dictionnaire de données et les fiches composants seront enrichis avec ces nouvelles décisions et mis dans le SSOT.