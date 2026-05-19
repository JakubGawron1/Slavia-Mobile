# Skopiuj jako scripts/signing-env.local.ps1 (plik jest w .gitignore).
# Potem:  . .\scripts\signing-env.local.ps1
#         flutter build apk --release

$env:ANDROID_KEYSTORE_PATH = "$env:USERPROFILE\.android\slavia-release.jks"
$env:ANDROID_KEYSTORE_PASSWORD = "Slavia"
$env:ANDROID_KEY_ALIAS = "slavia"
$env:ANDROID_KEY_PASSWORD = "Slavia"

Write-Host "ANDROID_KEYSTORE_PATH = $env:ANDROID_KEYSTORE_PATH"
