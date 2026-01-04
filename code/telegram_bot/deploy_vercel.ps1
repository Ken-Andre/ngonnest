# Script de déploiement Vercel pour NgonNest Telegram Bot (PowerShell)

Write-Host "🚀 Déploiement du bot NgonNest sur Vercel..." -ForegroundColor Green

# Vérifier que Vercel CLI est installé
if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Vercel CLI n'est pas installé." -ForegroundColor Red
    Write-Host "📦 Installation avec: npm install -g vercel" -ForegroundColor Yellow
    exit 1
}

# Vérifier les variables d'environnement
if (-not $env:TELEGRAM_TOKEN) {
    Write-Host "⚠️  TELEGRAM_TOKEN n'est pas défini." -ForegroundColor Yellow
    Write-Host "💡 Vous devrez le configurer dans le dashboard Vercel après le déploiement." -ForegroundColor Cyan
}

if (-not $env:GITHUB_TOKEN) {
    Write-Host "⚠️  GITHUB_TOKEN n'est pas défini (optionnel)." -ForegroundColor Yellow
    Write-Host "💡 L'intégration GitHub sera désactivée sans ce token." -ForegroundColor Cyan
}

# Déployer sur Vercel
Write-Host "📤 Déploiement en cours..." -ForegroundColor Cyan
vercel --prod

Write-Host ""
Write-Host "✅ Déploiement terminé!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "1. Notez l'URL fournie par Vercel (ex: https://your-project.vercel.app)"
Write-Host "2. Configurez les variables d'environnement dans le dashboard Vercel:"
Write-Host "   - TELEGRAM_TOKEN"
Write-Host "   - GITHUB_TOKEN (optionnel)"
Write-Host "   - GITHUB_REPO (optionnel, défaut: Ken-Andre/ngonnest)"
Write-Host "3. Redéployez avec: vercel --prod"
Write-Host "4. Configurez le webhook Telegram avec:"
Write-Host '   curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://YOUR_VERCEL_URL/api/bot"'
Write-Host ""
