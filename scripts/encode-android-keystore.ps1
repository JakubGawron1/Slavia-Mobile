# Koduje slavia-release.jks do Base64 (sekret ANDROID_KEYSTORE_BASE64 w GitHub Actions).
# Użycie:
#   .\scripts\encode-android-keystore.ps1
#   .\scripts\encode-android-keystore.ps1 -KeystorePath "$env:USERPROFILE\.android\slavia-release.jks"

param(
    [string]$KeystorePath = "$env:USERPROFILE\.android\slavia-release.jks"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $KeystorePath)) {
    Write-Error "Nie znaleziono keystore: $KeystorePath`nWygeneruj plik lub podaj -KeystorePath."
}

$bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $KeystorePath))
$b64 = [Convert]::ToBase64String($bytes)

Set-Clipboard -Value $b64

Write-Host "OK: $KeystorePath ($($bytes.Length) bajtów)"
Write-Host "Base64: $($b64.Length) znaków — skopiowano do schowka."
Write-Host ""
Write-Host "GitHub → Slavia-mobile → Settings → Secrets → Actions:"
Write-Host "  ANDROID_KEYSTORE_BASE64  = wklej ze schowka"
Write-Host "  ANDROID_KEYSTORE_PASSWORD = Slavia"
Write-Host "  ANDROID_KEY_ALIAS         = slavia"
Write-Host "  ANDROID_KEY_PASSWORD      = Slavia"
