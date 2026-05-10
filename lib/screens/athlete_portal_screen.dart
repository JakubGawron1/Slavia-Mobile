import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../models/auth.dart';
import '../models/athlete.dart';
import 'package:google_fonts/google_fonts.dart';

class AthletePortalScreen extends StatefulWidget {
  const AthletePortalScreen({super.key});

  @override
  State<AthletePortalScreen> createState() => _AthletePortalScreenState();
}

class _AthletePortalScreenState extends State<AthletePortalScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final athleteId = auth.user?.athleteId;

    if (athleteId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel Zawodnika')),
        body: const Center(child: Text('Twoje konto nie jest powiązane z profilem zawodnika.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Panel Zawodnika', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(Icons.fitness_center, size: 100, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiRow(athleteId, apiService),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Moje Wyniki (Oczekujące)'),
                  const SizedBox(height: 16),
                  _buildResultsList(athleteId, apiService),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddResultDialog(context, athleteId, apiService),
        label: const Text('Zgłoś wynik'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildKpiRow(String athleteId, ApiService apiService) {
    return FutureBuilder<Athlete>(
      future: apiService.getAthlete(athleteId), // Existing method
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final a = snapshot.data!;
        return Row(
          children: [
            Expanded(child: _buildKpiCard('Rwanie', '${a.bestSnatchKg ?? 0} kg', Icons.bolt, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildKpiCard('Podrzut', '${a.bestCleanJerkKg ?? 0} kg', Icons.flash_on, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildKpiCard('Dwubój', '${a.totalKg ?? 0} kg', Icons.emoji_events, Colors.amber)),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildResultsList(String athleteId, ApiService apiService) {
    return FutureBuilder<List<CompetitionResult>>(
      future: apiService.getAthleteResults(athleteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data?.where((r) => r.status == 'Pending').toList() ?? [];
        if (results.isEmpty) return const Text('Brak oczekujących zgłoszeń.');
        
        return Column(
          children: results.map((r) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${r.kind == "competition" ? "Zawody" : "Trening"}: ${r.total}kg'),
              subtitle: Text('${r.date} · ${r.location ?? "Brak lokalizacji"}'),
              trailing: const Badge(label: Text('Oczekuje'), backgroundColor: Colors.orange),
            ),
          )).toList(),
        );
      },
    );
  }

  void _showAddResultDialog(BuildContext context, String athleteId, ApiService apiService) {
    final snatchCtrl = TextEditingController();
    final cjCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    String kind = 'competition';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zgłoś wynik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: kind,
              items: const [
                DropdownMenuItem(value: 'competition', child: Text('Zawody')),
                DropdownMenuItem(value: 'training', child: Text('Trening')),
              ],
              onChanged: (v) => kind = v!,
              decoration: const InputDecoration(labelText: 'Rodzaj'),
            ),
            TextField(controller: snatchCtrl, decoration: const InputDecoration(labelText: 'Rwanie (kg)'), keyboardType: TextInputType.number),
            TextField(controller: cjCtrl, decoration: const InputDecoration(labelText: 'Podrzut (kg)'), keyboardType: TextInputType.number),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Lokalizacja (opcjonalnie)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              final s = double.tryParse(snatchCtrl.text) ?? 0;
              final c = double.tryParse(cjCtrl.text) ?? 0;
              try {
                await apiService.submitResult(
                  athleteId: athleteId,
                  date: DateTime.now().toIso8601String().substring(0, 10),
                  kind: kind,
                  location: locCtrl.text,
                  snatch: s,
                  cleanAndJerk: c,
                  total: s + c,
                );
                Navigator.pop(context);
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
              }
            },
            child: const Text('Wyślij'),
          ),
        ],
      ),
    );
  }
}
