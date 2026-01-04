#Requires -Version 5.1

param(
    [string]$TelegramToken,
    [string]$VercelUrl
)

Write-Host "🔗 Configuration du webhook Telegram pour NgonNest Bot" -ForegroundColor Green
Write-Host ""

if (-not $TelegramToken) {
    $TelegramToken = Read-Host "🔑 Entrez votre TELEGRAM_TOKEN"
}

if (-not $TelegramToken) {
    Write-Host "❌ Token requis!" -ForegroundColor Red
    exit 1
}

if (-not $VercelUrl) {
    $VercelUrl = Read-Host "🌐 Entrez votre URL Vercel (ex: https://your-project.vercel.app)"
}

if (-not $VercelUrl) {
    Write-Host "❌ URL requise!" -ForegroundColor Red
    exit 1
}

# Construire l'URL du webhook
$WebhookUrl = "$VercelUrl/api/bot"

Write-Host ""
Write-Host "📤 Configuration du webhook..." -ForegroundColor Cyan
Write-Host "URL: $WebhookUrl"

# Configurer le webhook
$SetWebhookUrl = "https://api.telegram.org/bot$TelegramToken/setWebhook?url=$WebhookUrl"

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

$WebhookInfoUrl = "https://api.telegram.org/bot$TelegramToken/getWebhookInfo"

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
