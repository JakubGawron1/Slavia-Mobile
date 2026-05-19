import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/athlete.dart';
import '../services/api_service.dart';
import '../utils/network_feedback.dart';

/// CRUD zawodników klubu — Admin / SuperAdmin (lista z `/api/athletes/admin`, bez cache publicznego).
class SuperAdminAthleteManagerScreen extends StatefulWidget {
  const SuperAdminAthleteManagerScreen({super.key});

  @override
  State<SuperAdminAthleteManagerScreen> createState() =>
      _SuperAdminAthleteManagerScreenState();
}

class _SuperAdminAthleteManagerScreenState
    extends State<SuperAdminAthleteManagerScreen> {
  late Future<List<Athlete>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAthletes();
  }

  Future<List<Athlete>> _loadAthletes() {
    final api = Provider.of<ApiService>(context, listen: false);
    return api.getAthletesAdmin();
  }

  void _reload() {
    setState(() {
      _future = _loadAthletes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zarządzanie zawodnikami',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<Athlete>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          friendlyNetworkError(snapshot.error!),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final athletes = snapshot.data ?? [];
            if (athletes.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Brak zawodników w bazie.',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: athletes.length,
              itemBuilder: (context, index) {
                final a = athletes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: a.imageUrl != null
                          ? NetworkImage(a.imageUrl!)
                          : null,
                      child: a.imageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      a.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${a.weightCategory ?? "Brak kat."} · ${a.birthYear ?? "Brak rocznika"}'
                      '${a.isActive ? '' : ' · nieaktywny'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showAthleteDialog(apiService, athlete: a);
                        }
                        if (val == 'delete') {
                          _showDeleteConfirm(a, apiService);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edytuj'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Usuń',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAthleteDialog(apiService),
        label: const Text('Nowy zawodnik'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAthleteDialog(ApiService apiService, {Athlete? athlete}) {
    final nameCtrl = TextEditingController(text: athlete?.fullName);
    final yearCtrl = TextEditingController(
      text: athlete?.birthYear?.toString(),
    );
    final catCtrl = TextEditingController(text: athlete?.weightCategory);
    final imgCtrl = TextEditingController(text: athlete?.imageUrl);
    var isActive = athlete?.isActive ?? true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(athlete == null ? 'Dodaj zawodnika' : 'Edytuj zawodnika'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Imię i nazwisko',
                  ),
                ),
                TextField(
                  controller: yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rok urodzenia',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria wagowa',
                  ),
                ),
                TextField(
                  controller: imgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL zdjęcia',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktywny w klubie'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{
                  'full_name': nameCtrl.text.trim(),
                  'birth_year': int.tryParse(yearCtrl.text.trim()),
                  'weight_category': catCtrl.text.trim(),
                  'image_url': imgCtrl.text.trim(),
                  'is_active': isActive,
                };
                try {
                  if (athlete == null) {
                    await apiService.createAthlete(data);
                  } else {
                    await apiService.updateAthlete(athlete.id, data);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  _reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        athlete == null
                            ? 'Zawodnik dodany'
                            : 'Zapisano zmiany',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(friendlyNetworkError(e)),
                    ),
                  );
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Athlete athlete, ApiService apiService) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń zawodnika'),
        content: Text(
          'Czy na pewno chcesz usunąć zawodnika ${athlete.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await apiService.deleteAthlete(athlete.id);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                _reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zawodnik usunięty')),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyNetworkError(e))),
                );
              }
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
