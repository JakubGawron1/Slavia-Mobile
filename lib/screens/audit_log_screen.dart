import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';


class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Logi systemowe')),
      body: FutureBuilder<List<AuditLog>>(
        future: apiService.getAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktor: ${log.actorUsername ?? "System"} (${log.actorRole ?? ""})'),
                    Text('Data: ${log.createdAt.substring(0, 16).replaceFirst("T", " ")}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
                trailing: Text(log.category.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                onTap: () {
                  if (log.details != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Szczegóły'),
                        content: SingleChildScrollView(child: Text(log.details!)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zamknij'))],
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
