# 🚀 NgonNest Telegram Bot - Guide de Déploiement

Ce guide couvre **3 options de déploiement** pour le bot Telegram NgonNest.

---

## 📋 Prérequis

### 1. Token Telegram Bot
1. Contactez [@BotFather](https://t.me/botfather) sur Telegram
2. Créez un nouveau bot avec `/newbot`
3. Copiez le token fourni

### 2. GitHub Personal Access Token (optionnel)
1. Allez sur GitHub → Settings → Developer settings → Personal access tokens
2. Créez un token avec les permissions `repo` (pour créer des issues)
3. Copiez le token

---

## 🎯 Option 1: Vercel (Serverless) - **RECOMMANDÉ**

### Avantages
- ✅ Gratuit (tier gratuit généreux)
- ✅ Auto-scaling automatique
- ✅ Zéro maintenance
- ✅ HTTPS inclus
- ✅ Déploiement en 2 minutes

### Étapes de déploiement

#### 1. Installer Vercel CLI
```bash
npm install -g vercel
```

#### 2. Préparer le projet
```bash
cd code/telegram_bot
```

#### 3. Déployer
```bash
vercel --prod
```

#### 4. Configurer les variables d'environnement
Dans le dashboard Vercel (https://vercel.com/dashboard):
- Allez dans votre projet → Settings → Environment Variables
- Ajoutez:
  - `TELEGRAM_TOKEN` = votre_token_telegram
  - `GITHUB_TOKEN` = votre_token_github (optionnel)
  - `GITHUB_REPO` = Ken-Andre/ngonnest

#### 5. Redéployer pour appliquer les variables
```bash
vercel --prod
```

#### 6. Configurer le webhook Telegram
Remplacez `YOUR_VERCEL_URL` par l'URL fournie par Vercel:
```bash
curl -X POST "https://api.telegram.org/bot<VOTRE_TOKEN>/setWebhook?url=https://YOUR_VERCEL_URL/api/bot"
```

#### 7. Vérifier le webhook
```bash
curl "https://api.telegram.org/bot<VOTRE_TOKEN>/getWebhookInfo"
```

### ✅ Test
Envoyez `/start` à votre bot sur Telegram. Vous devriez recevoir une réponse immédiate.

---

## 🐳 Option 2: Railway/Render (Container)

### Avantages
- ✅ Gratuit (tier gratuit disponible)
- ✅ Processus persistant (bon pour le polling)
- ✅ Facile à configurer
- ✅ Logs en temps réel

### Déploiement sur Railway

#### 1. Créer un compte sur [Railway.app](https://railway.app)

#### 2. Créer un nouveau projet
- Cliquez sur "New Project"
- Sélectionnez "Deploy from GitHub repo"
- Connectez votre repo `Ken-Andre/ngonnest`

#### 3. Configurer le projet
- Root Directory: `code/telegram_bot`
- Start Command: `python main.py`

#### 4. Ajouter les variables d'environnement
Dans Railway → Variables:
- `TELEGRAM_TOKEN` = votre_token_telegram
- `GITHUB_TOKEN` = votre_token_github (optionnel)
- `GITHUB_REPO` = Ken-Andre/ngonnest

#### 5. Déployer
Railway déploiera automatiquement. Le bot démarrera en mode polling.

### Déploiement sur Render

#### 1. Créer un compte sur [Render.com](https://render.com)

#### 2. Créer un nouveau Web Service
- Cliquez sur "New +" → "Web Service"
- Connectez votre repo GitHub
- Root Directory: `code/telegram_bot`
- Build Command: `pip install -r requirements.txt`
- Start Command: `python main.py`

#### 3. Configurer les variables d'environnement
Dans Render → Environment:
- `TELEGRAM_TOKEN` = votre_token_telegram
- `GITHUB_TOKEN` = votre_token_github (optionnel)
- `GITHUB_REPO` = Ken-Andre/ngonnest

#### 4. Déployer
Cliquez sur "Create Web Service". Le bot démarrera automatiquement.

---

## 🖥️ Option 3: VPS/Serveur Local

### Avantages
- ✅ Contrôle total
- ✅ Pas de limitations
- ✅ Peut tourner sur votre machine locale

### Déploiement

#### 1. Installer Python 3.9+
```bash
python --version  # Vérifier la version
```

#### 2. Cloner le repo (si pas déjà fait)
```bash
git clone https://github.com/Ken-Andre/ngonnest.git
cd ngonnest/code/telegram_bot
```

#### 3. Installer les dépendances
```bash
pip install -r requirements.txt
```

#### 4. Configurer les variables d'environnement
```bash
cp .env.example .env
# Éditez .env avec vos tokens
```

#### 5. Lancer le bot
```bash
python main.py
```

### Garder le bot actif 24/7

#### Option A: systemd (Linux)
Créez `/etc/systemd/system/ngonnest-bot.service`:
```ini
[Unit]
Description=NgonNest Telegram Bot
After=network.target

[Service]
Type=simple
User=votre_utilisateur
WorkingDirectory=/chemin/vers/ngonnest/code/telegram_bot
ExecStart=/usr/bin/python3 main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activez le service:
```bash
sudo systemctl enable ngonnest-bot
sudo systemctl start ngonnest-bot
sudo systemctl status ngonnest-bot
```

#### Option B: PM2 (Windows/Linux/Mac)
```bash
npm install -g pm2
pm2 start main.py --name ngonnest-bot --interpreter python3
pm2 save
pm2 startup
```

#### Option C: Screen (Linux)
```bash
screen -S ngonnest-bot
python main.py
# Appuyez sur Ctrl+A puis D pour détacher
```

---

## 🔍 Vérification du déploiement

### 1. Tester les commandes
Envoyez ces commandes à votre bot sur Telegram:
- `/start` - Message de bienvenue
- `/help` - Liste des commandes
- `/status` - État du bot et GitHub
- `/feedback` - Envoyer un feedback (crée une issue GitHub)
- `/bug` - Signaler un bug (crée une issue GitHub)

### 2. Vérifier les logs

**Vercel:**
```bash
vercel logs
```

**Railway/Render:**
Consultez les logs dans le dashboard web

**VPS/Local:**
```bash
# systemd
sudo journalctl -u ngonnest-bot -f

# PM2
pm2 logs ngonnest-bot

# Direct
# Les logs s'affichent dans le terminal
```

### 3. Tester l'intégration GitHub
1. Envoyez `/feedback Ceci est un test` au bot
2. Vérifiez qu'une issue est créée sur https://github.com/Ken-Andre/ngonnest/issues
3. L'issue devrait avoir le label `feedback`

---

## 🛠️ Dépannage

### Le bot ne répond pas

**Vercel (webhook):**
```bash
# Vérifier le webhook
curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo"

# Réinitialiser le webhook
curl -X POST "https://api.telegram.org/bot<TOKEN>/deleteWebhook"
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://YOUR_VERCEL_URL/api/bot"
```

**Railway/Render/VPS (polling):**
```bash
# Vérifier que le bot tourne
ps aux | grep python

# Redémarrer le bot
# (selon votre méthode de déploiement)
```

### Les issues GitHub ne se créent pas
1. Vérifiez que `GITHUB_TOKEN` est défini
2. Vérifiez que le token a les permissions `repo`
3. Vérifiez que `GITHUB_REPO` est correct (format: `owner/repo`)
4. Consultez les logs pour voir les erreurs

### Erreur "Conflict: terminated by other getUpdates"
Cela signifie que plusieurs instances du bot tournent en mode polling.
- Arrêtez toutes les instances
- Supprimez le webhook: `curl -X POST "https://api.telegram.org/bot<TOKEN>/deleteWebhook"`
- Relancez une seule instance

---

## 📊 Comparaison des options

| Critère | Vercel | Railway/Render | VPS/Local |
|---------|--------|----------------|-----------|
| **Coût** | Gratuit | Gratuit (limité) | Variable |
| **Setup** | 5 min | 10 min | 15-30 min |
| **Maintenance** | Zéro | Faible | Moyenne |
| **Uptime** | 99.9% | 99% | Dépend de vous |
| **Scaling** | Auto | Auto | Manuel |
| **Mode** | Webhook | Polling | Polling |
| **Logs** | Oui | Oui | Manuel |

---

## 🎯 Recommandation

**Pour la production:** Utilisez **Vercel** (Option 1)
- Gratuit, fiable, sans maintenance
- Parfait pour un bot de feedback/support

**Pour le développement:** Utilisez **VPS/Local** (Option 3)
- Facile à déboguer
- Redémarrage rapide

---

## 📝 Notes importantes

1. **Webhook vs Polling:**
   - Vercel utilise le mode webhook (le bot reçoit les messages via HTTP)
   - Railway/Render/VPS utilisent le mode polling (le bot interroge Telegram)
   - **Ne mélangez jamais les deux modes** pour le même bot

2. **Sécurité:**
   - Ne commitez JAMAIS vos tokens dans Git
   - Utilisez toujours des variables d'environnement
   - Le fichier `.env` est dans `.gitignore`

3. **Rate Limits:**
   - Telegram limite à 30 messages/seconde
   - GitHub API limite à 5000 requêtes/heure (avec token)

---

## 🆘 Support

En cas de problème:
1. Consultez les logs
2. Vérifiez les variables d'environnement
3. Testez avec `/status` pour voir l'état du bot
4. Créez une issue sur GitHub avec les logs d'erreur
