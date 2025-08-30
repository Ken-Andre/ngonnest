# NgonNest

NgonNest est une application mobile de gestion de commandes pour les restaurants, conçue pour fonctionner en mode hors‑ligne et faciliter l'expansion régionale et internationale. Ce dépôt GitHub constitue la **référence unique (Single Source of Truth)** du projet, centralisant tout le code source, la documentation technique et fonctionnelle, ainsi que les tickets.d

- `code/flutter/` – contient l'application mobile Flutter. Un fichier `.gitkeep` est présent pour conserver l'arborescence.
- `code/telegram_bot/` – contiendra le code du bot Telegram qui permet de créer automatiquement des issues GitHub depuis l'application【845134010872208†screenshot】.
- `docs/` – documentation du projet : cahier des charges, dictionnaire de données, matrice d'accès, guide utilisateur et plans de test.
- `issues/` – modèles pour créer des tickets de **bug** et de **feedback** dans GitHub Issues.

## Prérequis

- Flutter 3.x installé (https://flutter.dev)
- Dart 3.x
- Un éditeur de code (Visual Studio Code ou Android Studio)
- Optionnel : Node.js ou Python pour exécuter le bot Telegram (selon l'implémentation)

## Installation de l'application mobile

Clonez ce dépôt et installez les dépendances :

```bash
git clone https://github.com/Ken-Andre/ngonnest.git
cd ngonnest/code/flutter
flutter pub get
flutter run
```

L'application repose sur une base de données locale SQLite pour permettre une utilisation hors‑ligne et la synchronisation ultérieure lorsqu'une connexion est disponible. Les tests unitaires et fonctionnels se trouvent dans le dossier `docs/tests` et seront ajoutés progressivement.

## Lancer le bot Telegram

Le dossier `code/telegram_bot` contient l'implémentation du bot permettant de remonter des bugs et suggestions vers GitHub. Après avoir configuré vos variables d'environnement (`.env`), exécutez le bot selon les instructions du README spécifique dans ce dossier.

## Contribution

Les contributions se font via des tickets. Utilisez les modèles `issues/bug_template.md` et `issues/feedback_template.md` pour signaler un bug ou soumettre une amélioration. Les labels `bug`, `feedback` ainsi que les priorités `P1`, `P2` et `P3` permettent de classifier les demandes.

## Licence

Ce projet est sous licence propriétaire. Toute diffusion nécessite l'accord du Product Owner.
