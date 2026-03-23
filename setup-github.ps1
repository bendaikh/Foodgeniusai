# GitHub Auto-Deploy Setup Script
# Run this to initialize Git and push to GitHub

Write-Host "🚀 GitHub Auto-Deploy Setup for GourmetAI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if git is installed
Write-Host "Checking Git installation..." -ForegroundColor Yellow
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "❌ Git is not installed!" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/downloads" -ForegroundColor White
    exit 1
}
Write-Host "✅ Git is installed" -ForegroundColor Green

# Check if already a git repo
if (Test-Path ".git") {
    Write-Host "✅ Git repository already initialized" -ForegroundColor Green
} else {
    Write-Host "📦 Initializing Git repository..." -ForegroundColor Yellow
    git init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to initialize Git" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create GitHub Repository:" -ForegroundColor White
Write-Host "   - Go to: https://github.com/new" -ForegroundColor Gray
Write-Host "   - Repository name: gourmetai (or your choice)" -ForegroundColor Gray
Write-Host "   - Make it Private (recommended)" -ForegroundColor Gray
Write-Host "   - Do NOT initialize with README, .gitignore, or license" -ForegroundColor Gray
Write-Host "   - Click 'Create repository'" -ForegroundColor Gray
Write-Host ""

Write-Host "2. After creating GitHub repo, run these commands:" -ForegroundColor White
Write-Host ""
Write-Host "   # Add all files" -ForegroundColor Gray
Write-Host "   git add ." -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Create first commit" -ForegroundColor Gray
Write-Host "   git commit -m `"Initial commit - GourmetAI with auto-deploy`"" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Add your GitHub repository (replace with YOUR GitHub URL)" -ForegroundColor Gray
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/gourmetai.git" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Push to GitHub" -ForegroundColor Gray
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Configure GitHub Secrets:" -ForegroundColor White
Write-Host "   - Go to your GitHub repo → Settings → Secrets and variables → Actions" -ForegroundColor Gray
Write-Host "   - Add these 3 secrets:" -ForegroundColor Gray
Write-Host ""
Write-Host "     FTP_SERVER = ftp.yourdomain.com (your Hostinger FTP host)" -ForegroundColor Yellow
Write-Host "     FTP_USERNAME = your_ftp_username" -ForegroundColor Yellow
Write-Host "     FTP_PASSWORD = your_ftp_password" -ForegroundColor Yellow
Write-Host ""

Write-Host "4. Test Auto-Deploy:" -ForegroundColor White
Write-Host "   - Make a small change to any file" -ForegroundColor Gray
Write-Host "   - Commit: git add . && git commit -m `"Test auto-deploy`"" -ForegroundColor Gray
Write-Host "   - Push: git push" -ForegroundColor Gray
Write-Host "   - Go to GitHub → Actions tab → Watch deployment" -ForegroundColor Gray
Write-Host "   - Wait 3-5 minutes" -ForegroundColor Gray
Write-Host "   - Check your website!" -ForegroundColor Gray
Write-Host ""

Write-Host "📚 For detailed instructions, read:" -ForegroundColor Cyan
Write-Host "   GITHUB_AUTO_DEPLOY.md" -ForegroundColor White
Write-Host ""

Write-Host "✨ Files created:" -ForegroundColor Green
Write-Host "   ✅ .github/workflows/deploy.yml (GitHub Actions workflow)" -ForegroundColor White
Write-Host "   ✅ .gitignore (updated with sensitive files)" -ForegroundColor White
Write-Host "   ✅ GITHUB_AUTO_DEPLOY.md (complete guide)" -ForegroundColor White
Write-Host ""

Write-Host "🎉 Ready to set up auto-deployment!" -ForegroundColor Green
