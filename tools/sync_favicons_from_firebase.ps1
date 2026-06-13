# Downloads the admin-uploaded favicon from Firebase Storage and regenerates
# every static asset under web/ so Google Search and cold-start visitors see
# the same icon as the in-app tab (which loads from Storage via FaviconService).
#
# Run after uploading a new favicon in Admin Settings, then:
#   flutter build web --release
#   firebase deploy --only hosting
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\sync_favicons_from_firebase.ps1

$ErrorActionPreference = 'Stop'

$remoteUrl = 'https://firebasestorage.googleapis.com/v0/b/gourmetai-c432b.firebasestorage.app/o/app_assets%2Ffavicon.png?alt=media'
$sourceDir = Join-Path $PSScriptRoot 'favicon-source'
$sourcePath = Join-Path $sourceDir 'favicon-source.png'
$generateScript = Join-Path $PSScriptRoot 'generate_favicons.ps1'

New-Item -ItemType Directory -Force -Path $sourceDir | Out-Null

Write-Host "Downloading favicon from Firebase Storage..."
Invoke-WebRequest -Uri $remoteUrl -OutFile $sourcePath -UseBasicParsing

Write-Host "Regenerating web/ favicon bundle..."
& $generateScript -Source $sourcePath

Write-Host ""
Write-Host "Done. Next: bump ?v= on icon links in web/index.html if needed,"
Write-Host "then flutter build web --release && firebase deploy --only hosting"
