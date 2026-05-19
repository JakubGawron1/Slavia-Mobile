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
# Jedna linia, bez łamań — inaczej GNU base64 na CI rzuca „invalid input”.
$b64 = [Convert]::ToBase64String($bytes, [Base64FormattingOptions]::None)

$outTxt = Join-Path $env:TEMP "slavia-keystore-base64.txt"
[System.IO.File]::WriteAllText($outTxt, $b64, [Text.UTF8Encoding]::new($false))
Set-Clipboard -Value $b64

Write-Host "OK: $KeystorePath ($($bytes.Length) bajtów)"
Write-Host "Base64: $($b64.Length) znaków (jedna linia)."
Write-Host "Plik:   $outTxt  — otwórz, Ctrl+A, skopiuj do sekretu GitHub."
Write-Host "Schowek: skopiowano (wklej bez dodatkowych enterów / cudzysłowów)."
Write-Host ""
Write-Host "GitHub → Slavia-mobile → Settings → Secrets → Actions:"
Write-Host "  ANDROID_KEYSTORE_BASE64  = cała jedna linia z pliku lub schowka"
Write-Host "  ANDROID_KEYSTORE_PASSWORD = Slavia"
Write-Host "  ANDROID_KEY_ALIAS         = slavia"
Write-Host "  ANDROID_KEY_PASSWORD      = Slavia"
