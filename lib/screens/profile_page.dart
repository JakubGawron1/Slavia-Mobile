import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../utils/theme_provider.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _avatarUrlController.text = auth.user?.avatarUrl ?? auth.user?.athleteImageUrl ?? '';
  }

  Future<void> _pickAndUploadImage(ApiService apiService, AuthProvider auth) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await apiService.uploadImage(File(image.path), 'avatar');
      _avatarUrlController.text = url;
      // Optionally auto-save to profile
      await apiService.updateProfile(avatarUrl: url);
      await auth.refreshMe();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zdjęcie wgrane i zapisane.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd uploadu: $e')));
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    onPressed: _isUploading ? null : () => _pickAndUploadImage(apiService, auth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'Użytkownik',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _saveAccount(auth, apiService),
                        icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                        label: const Text('Zapisz zmiany'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection(context, 'Wygląd aplikacji', [
              ListTile(
                title: const Text('Tryb Ciemny'),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Motyw kolorystyczny', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: SlaviaPreset.values.map((preset) {
                    final isSelected = themeProvider.preset == preset;
                    return GestureDetector(
                      onTap: () => themeProvider.setPreset(preset),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getPresetPreviewColor(preset),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSelected ? [BoxShadow(color: _getPresetPreviewColor(preset).withOpacity(0.5), blurRadius: 10)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
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
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 4),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
        child: (url == null || url.isEmpty) ? Text(username?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _saveAccount(AuthProvider auth, ApiService apiService) async {
    if (_passwordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hasła się nie zgadzają')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await apiService.updateProfile(
        avatarUrl: _avatarUrlController.text,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );
      await auth.refreshMe();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konto zaktualizowane')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getPresetPreviewColor(SlaviaPreset preset) {
    switch (preset) {
      case SlaviaPreset.slavia: return const Color(0xFF00DC82);
      case SlaviaPreset.iron: return const Color(0xFF38BDF8);
      case SlaviaPreset.arena: return const Color(0xFFFBBF24);
      case SlaviaPreset.ruby: return const Color(0xFFEF4444);
      case SlaviaPreset.blackgym: return Colors.green;
      case SlaviaPreset.platform: return const Color(0xFF34D399);
      case SlaviaPreset.midnight: return const Color(0xFF6366F1);
      case SlaviaPreset.neon: return const Color(0xFFD946EF);
      case SlaviaPreset.pink: return const Color(0xFFEC4899);
    }
  }
}
