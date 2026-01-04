# 🚀 Quick Start - Déploiement en 5 minutes

## Option 1: Vercel (Recommandé)

### 1. Installer Vercel CLI
```bash
npm install -g vercel
```

### 2. Déployer
```bash
cd code/telegram_bot
vercel --prod
```

### 3. Configurer les variables
Dans le dashboard Vercel (https://vercel.com):
- Settings → Environment Variables
- Ajoutez `TELEGRAM_TOKEN` et `GITHUB_TOKEN`
- Redéployez: `vercel --prod`

### 4. Configurer le webhook
```bash
# Windows PowerShell
.\setup_webhook.ps1

# Linux/Mac
./setup_webhook.sh
```

### 5. Tester
Envoyez `/start` à votre bot sur Telegram ✅

---

## Option 2: Local (Développement)

### 1. Installer les dépendances
```bash
cd code/telegram_bot
pip install -r requirements.txt
```

### 2. Configurer les variables
```bash
cp .env.example .env
# Éditez .env avec vos tokens
```

### 3. Lancer le bot
```bash
python main.py
```

### 4. Tester
Envoyez `/start` à votre bot sur Telegram ✅

---

## 🆘 Problèmes?

Consultez [DEPLOYMENT.md](DEPLOYMENT.md) pour le guide complet.
