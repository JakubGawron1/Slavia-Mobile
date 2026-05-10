import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/athlete.dart';
import '../main.dart';


class TrainingLogScreen extends StatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final athleteId = auth.user?.athleteId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dziennik treningów'),
      ),
      body: athleteId == null
          ? const Center(child: Text('Brak profilu zawodnika'))
          : FutureBuilder<List<TrainingLogEntry>>(
              future: apiService.getTrainingLog(athleteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.sessionDate.substring(0, 10),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                if (e.authorUsername != null)
                                  Text(
                                    'Dodał: ${e.authorUsername}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                            if (e.title != null && e.title!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(e.title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                            const SizedBox(height: 8),
                            Text(e.notes),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: athleteId != null
          ? FloatingActionButton(
              onPressed: () => _showAddEntryDialog(context, athleteId, apiService),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddEntryDialog(BuildContext context, String athleteId, ApiService apiService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy wpis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tytuł (opcjonalnie)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Notatki', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              try {
                await apiService.createTrainingLogEntry(
                  athleteId,
                  _notesController.text,
                  _titleController.text,
                );
                Navigator.pop(context);
                setState(() {}); // Refresh
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
}
