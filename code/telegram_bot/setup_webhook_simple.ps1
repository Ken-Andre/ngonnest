#Requires -Version 5.1

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
$SetWebhookUrl = "https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook?url=$WEBHOOK_URL"

try {
    $response = Invoke-WebRequest -Uri $SetWebhookUrl -Method Post -UseBasicParsing
    $responseContent = $response.Content | ConvertFrom-Json

    Write-Host ""
    Write-Host "📋 Réponse de Telegram:" -ForegroundColor Yellow
    $responseContent | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Erreur lors de la configuration du webhook: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Vérifier le webhook
Write-Host ""
Write-Host "🔍 Vérification du webhook..." -ForegroundColor Cyan

$WebhookInfoUrl = "https://api.telegram.org/bot$TELEGRAM_TOKEN/getWebhookInfo"

try {
    $webhookResponse = Invoke-WebRequest -Uri $WebhookInfoUrl -Method Get -UseBasicParsing
    $webhookInfo = $webhookResponse.Content | ConvertFrom-Json

    $webhookInfo | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Erreur lors de la vérification du webhook: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Configuration terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 Testez votre bot en envoyant /start sur Telegram" -ForegroundColor Cyan
