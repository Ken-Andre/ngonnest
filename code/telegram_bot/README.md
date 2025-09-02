# Telegram Bot - NgonNest

Bot Telegram pour NgonNest avec commandes de base pour tester les retours précoces.

## Fonctionnalités

- `/start` : Message de bienvenue "Bienvenue !"
- `/help` : Liste des commandes disponibles avec descriptions

## Installation

1. **Installer les dépendances :**
```bash
pip install -r requirements.txt
```

2. **Créer le fichier .env :**
```bash
cp .env.example .env
# Éditez .env avec votre token Telegram valide
```

3. **Tester le code :**
```bash
python test.py  # Teste la version tamponnée (library-based)
# ou
python -m py_compile simple_bot.py  # Teste la version directe (API-based)
```

4. **Lancer le bot :**
### ✅ Version recommandée (API directe) :
```bash
python simple_bot.py
```
*Plus simple, plus fiable, aucune dépendance externe problématique*

### 🔧 Version alternative (avec bibliothèques externes) :
```bash
python main.py
```
*Attention : peut avoir des problèmes de compatibilité avec certaines versions de python-telegram-bot*

## Structure du projet

```
code/telegram_bot/
├── main.py          # Code principal du bot
├── test.py          # Script de test pour valider la configuration
├── requirements.txt # Dépendances Python
├── .env            # Variables d'environnement (token)
├── .gitignore      # Fichiers à ignorer
└── README.md       # Documentation
```

## Critères d'acceptation

- ✅ Bot actif avec /start ("Bienvenue !") et /help (liste commandes)
- ✅ Réponse <5s
- ✅ Code dans /code/telegram_bot

## Configuration

### Variables d'environnement

Le fichier `.env` contient :
```
TELEGRAM_TOKEN=votre_token_telegram_ici
```

Pour obtenir un token Telegram, contactez [@BotFather](https://t.me/botfather) sur Telegram.

### Logging

Le bot utilise le module logging pour tracer les erreurs. Les logs sont envoyés vers la console avec le format :
```
%(asctime)s - %(name)s - %(levelname)s - %(message)s
```

## Dépannage

Si le bot ne fonctionne pas :

1. **Vérifiez le token** : Assurez-vous que le token dans `.env` est valide
2. **Installez les dépendances** : `pip install -r requirements.txt`
3. **Testez la configuration** : `python test.py`
4. **Vérifiez les logs** : Lancez le bot pour voir les messages d'erreur

## Tests

Le script `test.py` permet de valider :
- L'installation des dépendances
- La configuration des variables d'environnement
- La syntaxe du code principal

```bash
python test.py
```
