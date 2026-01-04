#!/bin/bash
# Script pour configurer le webhook Telegram

echo "🔗 Configuration du webhook Telegram pour NgonNest Bot"
echo ""

# Demander le token
read -p "🔑 Entrez votre TELEGRAM_TOKEN: " TELEGRAM_TOKEN

if [ -z "$TELEGRAM_TOKEN" ]; then
    echo "❌ Token requis!"
    exit 1
fi

# Demander l'URL Vercel
read -p "🌐 Entrez votre URL Vercel (ex: https://your-project.vercel.app): " VERCEL_URL

if [ -z "$VERCEL_URL" ]; then
    echo "❌ URL requise!"
    exit 1
fi

# Construire l'URL du webhook
WEBHOOK_URL="${VERCEL_URL}/api/bot"

echo ""
echo "📤 Configuration du webhook..."
echo "URL: $WEBHOOK_URL"

# Configurer le webhook
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/setWebhook?url=${WEBHOOK_URL}")

echo ""
echo "📋 Réponse de Telegram:"
echo "$RESPONSE"

# Vérifier le webhook
echo ""
echo "🔍 Vérification du webhook..."
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/getWebhookInfo")

echo "$WEBHOOK_INFO" | python3 -m json.tool

echo ""
echo "✅ Configuration terminée!"
echo ""
echo "🧪 Testez votre bot en envoyant /start sur Telegram"
