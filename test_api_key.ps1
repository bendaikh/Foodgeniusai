$apiKey = "AIzaSyClG1zFNb6sflC0yKO-Mmbawqq6ReqazpI"
$url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey"

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Firebase API Key Tester" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing API Key: $apiKey" -ForegroundColor Yellow
Write-Host ""

$body = @{
    email = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@test.com"
    password = "TestPassword123"
    returnSecureToken = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $body -ErrorAction Stop
    
    Write-Host "SUCCESS! API Key Works!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Firebase API key is valid and working correctly!" -ForegroundColor Green
    Write-Host "The error in your Flutter app must be coming from somewhere else." -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "API Key Test FAILED" -ForegroundColor Red
    Write-Host ""
    
    if ($_.ErrorDetails) {
        try {
            $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
            $errorMessage = $errorResponse.error.message
            Write-Host "Error: $errorMessage" -ForegroundColor Red
            Write-Host ""
            
            # Check error type and provide solution
            $errorUpper = $errorMessage.ToUpper()
            
            if ($errorUpper.Contains("API") -and ($errorUpper.Contains("KEY") -or $errorUpper.Contains("INVALID"))) {
                Write-Host "PROBLEM: API Key is INVALID or RESTRICTED" -ForegroundColor Red
                Write-Host ""
                Write-Host "HOW TO FIX:" -ForegroundColor Yellow
                Write-Host "1. Open: https://console.cloud.google.com/apis/credentials?project=gourmetai-c432b" -ForegroundColor White
                Write-Host "2. Click on your Web API Key" -ForegroundColor White
                Write-Host "3. Set Application restrictions to 'None'" -ForegroundColor White
                Write-Host "4. Set API restrictions to 'Dont restrict key'" -ForegroundColor White
                Write-Host "5. Save and wait 5-10 minutes" -ForegroundColor White
            }
            
            if ($errorUpper.Contains("OPERATION") -and $errorUpper.Contains("NOT") -and $errorUpper.Contains("ALLOWED")) {
                Write-Host "PROBLEM: Email/Password auth is NOT ENABLED" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "HOW TO FIX:" -ForegroundColor Yellow
                Write-Host "1. Open: https://console.firebase.google.com/" -ForegroundColor White
                Write-Host "2. Select: gourmetai-c432b" -ForegroundColor White
                Write-Host "3. Click Authentication > Sign-in method" -ForegroundColor White
                Write-Host "4. Enable Email/Password provider" -ForegroundColor White
                Write-Host "5. Save" -ForegroundColor White
            }
            
            if ($errorUpper.Contains("EMAIL") -and $errorUpper.Contains("EXISTS")) {
                Write-Host "API Key is VALID! (Email already exists)" -ForegroundColor Green
                Write-Host "This is actually a good sign!" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "Raw error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
