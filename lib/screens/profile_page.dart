import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../main.dart';
import '../utils/theme_provider.dart';
import '../ui/slavia_ui.dart';
import '../widgets/biometric_gate.dart';
import '../services/api_service.dart';
import '../services/app_update_service.dart';
import '../config/mobile_github_release.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _avatarUrlController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _isUploading = false;
  bool _biometricUnlock = false;
  final _birthYearController = TextEditingController();
  String? _gender;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _avatarUrlController.text =
        auth.user?.avatarUrl ?? auth.user?.athleteImageUrl ?? '';
    _birthYearController.text = auth.user?.athleteBirthYear?.toString() ?? '';
    _gender = auth.user?.athleteGender;
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _biometricUnlock = p.getBool(kBiometricUnlockPrefKey) ?? false,
    );
  }

  Future<void> _pickAndUploadImage(
    ApiService apiService,
    AuthProvider auth,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await apiService.uploadImage(File(image.path), 'avatar');
      _avatarUrlController.text = url;
      // Optionally auto-save to profile
      await apiService.updateProfile(avatarUrl: url);
      await auth.refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zdjęcie wgrane i zapisane.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd uploadu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final user = auth.user;

    final profileImg = user?.avatarUrl ?? user?.athleteImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil i Ustawienia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildAvatar(profileImg, user?.username),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 18,
                  child: IconButton(
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                    onPressed: _isUploading
                        ? null
                        : () => _pickAndUploadImage(apiService, auth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'Użytkownik',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSection(context, 'Bezpieczeństwo na urządzeniu', [
              SwitchListTile.adaptive(
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Logowanie biometryczne'),
                subtitle: const Text(
                  'Szybkie odblokowanie aplikacji oraz logowanie bez hasła (Face ID, odcisk lub kod).',
                ),
                value: _biometricUnlock,
                onChanged: (v) async {
                  final p = await SharedPreferences.getInstance();
                  if (!v) {
                    await p.setBool(kBiometricUnlockPrefKey, false);
                    if (mounted) setState(() => _biometricUnlock = false);
                    return;
                  }
                  final auth = LocalAuthentication();
                  final supported = await auth.isDeviceSupported();
                  final canBio = await auth.canCheckBiometrics;
                  if (!supported && !canBio) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'To urządzenie nie obsługuje biometrii ani bezpiecznego kodu ekranu w tej konfiguracji.',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    final ok = await auth.authenticate(
                      localizedReason: 'Włącz ochronę biometryczną dla CKS Slavia',
                      options: const AuthenticationOptions(
                        stickyAuth: true,
                        biometricOnly: false,
                      ),
                    );
                    if (!ok) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Anulowano — ochrona nie została włączona.',
                            style: GoogleFonts.outfit(),
                          ),
                        ),
                      );
                      return;
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Biometria: $e',
                          style: GoogleFonts.outfit(),
                        ),
                      ),
                    );
                    return;
                  }
                  await p.setBool(kBiometricUnlockPrefKey, true);
                  if (mounted) setState(() => _biometricUnlock = true);
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection(context, 'Ustawienia konta', [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _avatarUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Awatara',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Nowe hasło',
                        hintText: 'Zostaw puste, by nie zmieniać',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Powtórz hasło',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    if ((auth.user?.roles ?? []).contains('Athlete')) ...[
                      const SizedBox(height: 24),
                      SlaviaUi.sectionHeader(
                        context,
                        'Dane zawodnika',
                        accent: Theme.of(context).colorScheme.primary,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Płeć',
                          prefixIcon: Icon(Icons.transgender),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Mężczyzna')),
                          DropdownMenuItem(value: 'female', child: Text('Kobieta')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _birthYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rok urodzenia',
                          hintText: 'np. 2005',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveAccount(auth, apiService),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Zapisz zmiany'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: SlaviaUi.cardShell(
                  context,
                  borderTint: Theme.of(context).colorScheme.primary,
                  radius: SlaviaUi.radiusXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SlaviaUi.homeBadge(context, 'Jak na stronie klubu'),
                    const SizedBox(height: 12),
                    Text(
                      'Wygląd aplikacji',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Preset i tryb jasny/ciemny zapisują się na tym urządzeniu. '
                      'Po zalogowaniu mogą też zapisać się na koncie — tak jak w przeglądarce.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.45,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SlaviaUi.sectionHeader(
                      context,
                      'Jasność ekranu',
                      accent: Theme.of(context).colorScheme.secondary,
                      icon: Icons.brightness_6_rounded,
                    ),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.settings_suggest_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Jasny'),
                          icon: Icon(Icons.light_mode_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Ciemny'),
                          icon: Icon(Icons.dark_mode_outlined, size: 18),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (next) {
                        if (next.isEmpty) return;
                        themeProvider.setThemeMode(next.first);
                      },
                    ),
                    const SizedBox(height: 22),
                    SlaviaUi.sectionHeader(
                      context,
                      'Preset kolorystyczny',
                      accent: Theme.of(context).colorScheme.primary,
                      icon: Icons.palette_outlined,
                    ),
                    const SizedBox(height: 6),
                    ...SlaviaAppearanceLabels.displayOrder.map((preset) {
                      final selected = themeProvider.preset == preset;
                      final accent = themeProvider.previewAccent(preset);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(SlaviaUi.radiusMd),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(SlaviaUi.radiusMd),
                            onTap: () => themeProvider.setPreset(preset),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(SlaviaUi.radiusMd),
                                border: Border.all(
                                  color: selected
                                      ? accent.withValues(alpha: 0.65)
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.25),
                                  width: selected ? 2 : 1,
                                ),
                                color: selected
                                    ? accent.withValues(alpha: 0.08)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          SlaviaAppearanceLabels.title(
                                            preset,
                                          ),
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          SlaviaAppearanceLabels.subtitle(
                                            preset,
                                          ),
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.58),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: accent,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(context, 'Aktualizacje', [
              ListTile(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: const Text('Sprawdź wersję (GitHub Releases)'),
                subtitle: Text(
                  MobileGithubRelease.isConfigured
                      ? 'Repo: ${MobileGithubRelease.repo}'
                      : 'Ustaw przy buildzie: SLAVIA_MOBILE_GITHUB_REPO=owner/repo',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  if (!MobileGithubRelease.isConfigured) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Brak SLAVIA_MOBILE_GITHUB_REPO — nie można sprawdzić wersji.',
                        ),
                      ),
                    );
                    return;
                  }
                  final msg =
                      await AppUpdateService.instance.checkAndOfferUpdate(
                    context,
                    ignoreDismissed: true,
                  );
                  if (!context.mounted) return;
                  if (msg != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String? username) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 4,
        ),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: (url != null && url.isNotEmpty)
            ? NetworkImage(url)
            : null,
        child: (url == null || url.isEmpty)
            ? Text(
                username?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Future<void> _saveAccount(AuthProvider auth, ApiService apiService) async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hasła się nie zgadzają')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await apiService.updateProfile(
        avatarUrl: _avatarUrlController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      if ((auth.user?.roles ?? []).contains('Athlete')) {
        await apiService.updateMyAthleteProfile(
          birthYear: int.tryParse(_birthYearController.text),
          gender: _gender,
        );
      }

      await auth.refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Konto zaktualizowane')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

}
