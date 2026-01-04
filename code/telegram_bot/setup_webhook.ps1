# Script pour configurer le webhook Telegram (PowerShell)

Write-Host "🔗 Configuration du webhook Telegram pour NgonNest Bot" -ForegroundColor Green
Write-Host ""

# Demander le token
$TELEGRAM_TOKEN = Read-Host "🔑 Entrez votre TELEGRAM_TOKEN"

if ([string]::IsNullOrWhiteSpace($TELEGRAM_TOKEN)) {
    Write-Host "❌ Token requis!" -ForegroundColor Red
    exit 1
}

# Demander l'URL Vercel
$VERCEL_URL = Read-Host "🌐 Entrez votre URL Vercel (ex: https://your-project.vercel.app)"

if ([string]::IsNullOrWhiteSpace($VERCEL_URL)) {
    Write-Host "❌ URL requise!" -ForegroundColor Red
    exit 1
}

# Construire l'URL du webhook
$WEBHOOK_URL = "$VERCEL_URL/api/bot"

Write-Host ""
Write-Host "📤 Configuration du webhook..." -ForegroundColor Cyan
Write-Host "URL: $WEBHOOK_URL"

# Configurer le webhook
$setWebhookUrl = "https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook?url=$WEBHOOK_URL"
try {
    $response = Invoke-RestMethod -Uri $setWebhookUrl -Method Post
    Write-Host ""
    Write-Host "📋 Réponse de Telegram:" -ForegroundColor Yellow
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Erreur lors de la configuration du webhook: $_" -ForegroundColor Red
    exit 1
}

# Vérifier le webhook
Write-Host ""
Write-Host "🔍 Vérification du webhook..." -ForegroundColor Cyan
$webhookInfoUrl = "https://api.telegram.org/bot$TELEGRAM_TOKEN/getWebhookInfo"
try {
    $webhookInfo = Invoke-RestMethod -Uri $webhookInfoUrl -Method Get
    $webhookInfo | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Erreur lors de la vérification du webhook: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Configuration terminée !" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 Testez votre bot en envoyant /start sur Telegram" -ForegroundColor Cyan