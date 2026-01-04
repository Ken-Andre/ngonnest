#!/bin/bash
# Script de déploiement Vercel pour NgonNest Telegram Bot

echo "🚀 Déploiement du bot NgonNest sur Vercel..."

# Vérifier que Vercel CLI est installé
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI n'est pas installé."
    echo "📦 Installation avec: npm install -g vercel"
    exit 1
fi

# Vérifier les variables d'environnement
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo "⚠️  TELEGRAM_TOKEN n'est pas défini."
    echo "💡 Vous devrez le configurer dans le dashboard Vercel après le déploiement."
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  GITHUB_TOKEN n'est pas défini (optionnel)."
    echo "💡 L'intégration GitHub sera désactivée sans ce token."
fi

# Déployer sur Vercel
echo "📤 Déploiement en cours..."
vercel --prod

echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Notez l'URL fournie par Vercel (ex: https://your-project.vercel.app)"
echo "2. Configurez les variables d'environnement dans le dashboard Vercel:"
echo "   - TELEGRAM_TOKEN"
echo "   - GITHUB_TOKEN (optionnel)"
echo "   - GITHUB_REPO (optionnel, défaut: Ken-Andre/ngonnest)"
echo "3. Redéployez avec: vercel --prod"
echo "4. Configurez le webhook Telegram avec:"
echo "   curl -X POST \"https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://YOUR_VERCEL_URL/api/bot\""
echo ""
