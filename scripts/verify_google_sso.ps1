<#
.SYNOPSIS
    SafeTalk - Google SSO & Firebase Configuration Verifier (Wave 5 - A5.1, A5.2, A5.3)

.DESCRIPTION
    Validates google-services.json for Android OAuth clients (client_type: 1),
    detects local keystores, and displays the SHA-1 registration commands.
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SafeTalk - Google SSO Readiness Diagnostic (Wave 5)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
$googleServicesPath = Join-Path $projectRoot "app\android\app\google-services.json"
$uploadKeystorePath = Join-Path $projectRoot "app\android\app\upload-keystore.jks"
$debugKeystorePath = Join-Path $env:USERPROFILE ".android\debug.keystore"

# 1. Check google-services.json
Write-Host "`n[1] Checking google-services.json..." -ForegroundColor Yellow
if (Test-Path $googleServicesPath) {
    Write-Host "  [OK] Found google-services.json at: $googleServicesPath" -ForegroundColor Green
    try {
        $json = Get-Content $googleServicesPath -Raw | ConvertFrom-Json
        $client = $json.client | Where-Object { $_.client_info.android_client_info.package_name -eq "com.safetalk.app" }
        
        if ($client) {
            Write-Host "  [OK] Package name 'com.safetalk.app' matches client config." -ForegroundColor Green
            $oauthClients = $client.oauth_client
            $hasAndroidClient = $false
            $hasWebClient = $false

            foreach ($oauth in $oauthClients) {
                if ($oauth.client_type -eq 1) {
                    $hasAndroidClient = $true
                    $sha1 = $oauth.android_info.certificate_hash
                    Write-Host "  [OK] Registered Android OAuth Client (type 1) SHA-1: $sha1" -ForegroundColor Green
                } elseif ($oauth.client_type -eq 3) {
                    $hasWebClient = $true
                    Write-Host "  [OK] Web OAuth Client (type 3) present." -ForegroundColor Green
                }
            }

            if (-not $hasAndroidClient) {
                Write-Host "  [!] WARNING: No Android OAuth client (client_type: 1) found in google-services.json!" -ForegroundColor Red
                Write-Host "      Google Sign-In will fail with ApiException: 10 until SHA-1 is registered in Firebase Console." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [!] WARNING: Package 'com.safetalk.app' not found in google-services.json." -ForegroundColor Red
        }
    } catch {
        Write-Host "  [!] Failed to parse google-services.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [!] MISSING: app\android\app\google-services.json does not exist." -ForegroundColor Red
    Write-Host "      Download google-services.json from Firebase Console after registering fingerprints." -ForegroundColor Yellow
}

# 2. Check Keystores
Write-Host "`n[2] Checking Signing Keystores for SHA-1 Extraction..." -ForegroundColor Yellow

# Debug Keystore
if (Test-Path $debugKeystorePath) {
    Write-Host "  [OK] Debug Keystore found: $debugKeystorePath" -ForegroundColor Green
    Write-Host "       Extract SHA-1: keytool -list -v -alias androiddebugkey -keystore `"$debugKeystorePath`" -storepass android -keypass android" -ForegroundColor Gray
} else {
    Write-Host "  [-] Debug Keystore not yet generated at $debugKeystorePath" -ForegroundColor Gray
    Write-Host "      (Generated automatically on first 'flutter run -d android')" -ForegroundColor Gray
}

# Upload Keystore
if (Test-Path $uploadKeystorePath) {
    Write-Host "  [OK] Upload Keystore found: $uploadKeystorePath" -ForegroundColor Green
    Write-Host "       Extract SHA-1: keytool -list -v -alias upload -keystore `"$uploadKeystorePath`"" -ForegroundColor Gray
} else {
    Write-Host "  [-] Upload Keystore not found at $uploadKeystorePath" -ForegroundColor Gray
    Write-Host "      Generate via: keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload" -ForegroundColor Gray
}

# 3. Registration Guide Summary
Write-Host "`n[3] Required Fingerprint Checklist (Firebase Console -> Project Settings -> Your Apps -> Android):" -ForegroundColor Yellow
Write-Host "  1. [ ] Debug SHA-1 (for local flutter run)" -ForegroundColor White
Write-Host "  2. [ ] Upload Keystore SHA-1 (for release APKs and CI builds)" -ForegroundColor White
Write-Host "  3. [ ] Google Play App Signing SHA-1 (from Play Console -> Release -> Setup -> App Signing)" -ForegroundColor White
Write-Host "`nAfter registering, re-download google-services.json and run this script again to confirm.`n" -ForegroundColor Cyan
