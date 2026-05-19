# Podpisywanie APK Android — CKS Slavia Mobile

## Twój keystore release (Slavia)

Po wygenerowaniu pliku `slavia-release.jks` (alias **`slavia`**, hasło keystore i klucza: **`Slavia`**) używaj **zawsze tego samego pliku** lokalnie i w GitHub Actions.

| Pole | Wartość |
|------|---------|
| Plik | `slavia-release.jks` (zalecane: `%USERPROFILE%\.android\slavia-release.jks`) |
| Alias | `slavia` |
| Hasło keystore | `Slavia` |
| Hasło klucza | `Slavia` (przy `keytool -genkey` zwykle takie samo) |
| Ważność | 10 000 dni (~27 lat) |

**Kopia zapasowa:** skopiuj `.jks` na dysk zewnętrzny / menedżer haseł zespołu. **Bez pliku i hasła nie odzyskasz podpisu** — nie da się wtedy wydawać aktualizacji tej samej aplikacji w sklepie / OTA.

---

## Krok 1 — dokończ `keytool` (jeśli jeszcze wisi)

W oknie keytool na pytanie:

`Is CN=Jakub Gawron, OU=Slavia-it, O=CKS Slavia, ... correct?`

wpisz **`yes`** i Enter.

Znaki `?` zamiast `ś`, `ą` w PowerShellu to normalne kodowanie konsoli — certyfikat i tak działa.

Przenieś plik z pulpitu do stałej lokalizacji (opcjonalnie, zalecane):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.android" | Out-Null
Move-Item -Force "$env:USERPROFILE\Desktop\slavia-release.jks" "$env:USERPROFILE\.android\slavia-release.jks"
```

Sprawdź, że plik istnieje:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\slavia-release.jks" -alias slavia
```

(hasło: `Slavia`)

---

## Krok 2 — build release lokalnie (ten sam podpis co CI)

W PowerShellu (sesja na czas buildu):

```powershell
$env:ANDROID_KEYSTORE_PATH = "$env:USERPROFILE\.android\slavia-release.jks"
$env:ANDROID_KEYSTORE_PASSWORD = "Slavia"
$env:ANDROID_KEY_ALIAS = "slavia"
$env:ANDROID_KEY_PASSWORD = "Slavia"

cd C:\Users\jakub\Desktop\Slavia-mobile
git fetch --tags
flutter build apk --release
```

APK: `build\app\outputs\flutter-apk\app-release.apk`

Możesz też załadować zmienne z szablonu (skopiuj `scripts\signing-env.example.ps1` → `scripts\signing-env.local.ps1`, uzupełnij ścieżkę, **nie commituj** `signing-env.local.ps1`):

```powershell
. .\scripts\signing-env.local.ps1
flutter build apk --release
```

---

## Krok 3 — sekrety GitHub Actions (CI)

Repo: **Slavia-mobile** → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

| Sekret | Wartość |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | plik `.jks` zakodowany w Base64 (patrz niżej) |
| `ANDROID_KEYSTORE_PASSWORD` | `Slavia` |
| `ANDROID_KEY_ALIAS` | `slavia` |
| `ANDROID_KEY_PASSWORD` | `Slavia` |

### Base64 keystore (Windows)

```powershell
.\scripts\encode-android-keystore.ps1 -KeystorePath "$env:USERPROFILE\.android\slavia-release.jks"
```

Skrypt wypisze długość i skopiuje Base64 do schowka — wklej całość jako wartość sekretu `ANDROID_KEYSTORE_BASE64`.

Alternatywnie ręcznie (musi być **jedna linia**):

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("$env:USERPROFILE\.android\slavia-release.jks"),
  [Base64FormattingOptions]::None
) | Set-Content -NoNewline -Encoding ascii "$env:TEMP\slavia-keystore-base64.txt"
```

### Błąd CI: `base64: invalid input`

1. Usuń sekret `ANDROID_KEYSTORE_BASE64` i utwórz go **od nowa**.
2. Uruchom `.\scripts\encode-android-keystore.ps1` — wklej z pliku `%TEMP%\slavia-keystore-base64.txt` (Ctrl+A), **bez** cudzysłowów i bez nowej linii na końcu.
3. Nie wklejaj ścieżki do `.jks` ani hasła — tylko ciąg Base64 (~kilka tysięcy znaków).

---

## Krok 4 — tag i release na GitHubie

Workflow **Release APK** (`.github/workflows/release.yml`) buduje APK przy pushu tagu `v*` (np. `v1.0.1-dev`).

```powershell
cd C:\Users\jakub\Desktop\Slavia-mobile
git pull
git tag v1.0.2-dev
git push origin v1.0.2-dev
```

W **Actions** sprawdź log kroku **Verify Android release signing** — powinno być `Release keystore: OK`.

APK trafi do **GitHub Releases** przy tym tagu.

Ręczny build bez tagu: **Actions** → **Release APK** → **Run workflow** (artifact `app-release-apk`).

---

## Dlaczego instalacja „nie działa” / wymaga odinstalowania?

Android akceptuje aktualizację tylko przy **tym samym podpisie**.

| Źródło APK | Keystore |
|------------|----------|
| Lokalny release **bez** zmiennych `ANDROID_*` | Debug PC |
| CI **bez** sekretów | Debug runnera |
| Lokalny + CI **z** `slavia-release.jks` | Ten sam podpis |

**Po przejściu na release keystore:** odinstaluj starą apkę z telefonu (podpisana debug / starym CI), potem instaluj tylko z GitHub Releases lub lokalnego buildu z tym samym `.jks`.

---

## Zmienne środowiskowe (podsumowanie)

| Zmienna | Opis |
|---------|------|
| `ANDROID_KEYSTORE_PATH` | Ścieżka do `.jks` (lokalnie; w CI ustawia workflow) |
| `ANDROID_KEYSTORE_PASSWORD` | Hasło keystore |
| `ANDROID_KEY_ALIAS` | `slavia` |
| `ANDROID_KEY_PASSWORD` | Hasło klucza |

`android/app/build.gradle.kts` podpina release signing, gdy plik z `ANDROID_KEYSTORE_PATH` istnieje; inaczej — debug (tylko do testów).

---

## versionCode i aktualizacje w aplikacji

- **versionName** — z tagu Git (`v1.0.1-dev`) lub najnowszego `v*`.
- **versionCode** — `git rev-list --count HEAD * 1000 + buildNumber` z `pubspec.yaml`.

Przed release: `git fetch --tags` i `git pull`, żeby numer wersji zgadzał się z CI.

---

## Bezpieczeństwo

- **Nie** commituj `.jks`, `key.properties`, `signing-env.local.ps1`.
- **Nie** wklejaj haseł do issue / czatu — tylko GitHub Secrets.
- Hasło `Slavia` w tym dokumencie jest zgodne z Twoją konfiguracją; w produkcji rozważ silniejsze hasło i rotację kopii zapasowej.
