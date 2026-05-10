import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/athlete.dart';
import 'package:google_fonts/google_fonts.dart';

class SuperAdminAthleteManagerScreen extends StatefulWidget {
  const SuperAdminAthleteManagerScreen({super.key});

  @override
  State<SuperAdminAthleteManagerScreen> createState() => _SuperAdminAthleteManagerScreenState();
}

class _SuperAdminAthleteManagerScreenState extends State<SuperAdminAthleteManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Zarządzanie Zawodnikami', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: FutureBuilder<List<Athlete>>(
        future: apiService.getAthletes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Błąd: ${snapshot.error}'));
          final athletes = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: athletes.length,
            itemBuilder: (context, index) {
              final a = athletes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: a.imageUrl != null ? NetworkImage(a.imageUrl!) : null,
                    child: a.imageUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${a.weightCategory ?? "Brak kat."} · ${a.birthYear ?? "Brak rocznika"}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _showAthleteDialog(apiService, athlete: a);
                      if (val == 'delete') _showDeleteConfirm(a, apiService);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                      const PopupMenuItem(value: 'delete', child: Text('Usuń', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
    final yearCtrl = TextEditingController(text: athlete?.birthYear?.toString());
    final catCtrl = TextEditingController(text: athlete?.weightCategory);
    final imgCtrl = TextEditingController(text: athlete?.imageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(athlete == null ? 'Dodaj zawodnika' : 'Edytuj zawodnika'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Imię i nazwisko')),
              TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Rok urodzenia'), keyboardType: TextInputType.number),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Kategoria wagowa')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'URL zdjęcia')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'full_name': nameCtrl.text,
                'birth_year': int.tryParse(yearCtrl.text),
                'weight_category': catCtrl.text,
                'image_url': imgCtrl.text,
              };
              try {
                if (athlete == null) {
                  await apiService.createAthlete(data);
                } else {
                  await apiService.updateAthlete(athlete.id, data);
                }
                Navigator.pop(context);
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(Athlete athlete, ApiService apiService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń zawodnika'),
        content: Text('Czy na pewno chcesz usunąć zawodnika ${athlete.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () async {
              try {
                await apiService.deleteAthlete(athlete.id);
                Navigator.pop(context);
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
              }
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
