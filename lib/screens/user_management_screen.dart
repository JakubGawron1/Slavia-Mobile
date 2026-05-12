import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Zarządzanie kadrą',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<SlaviaUser>>(
        future: apiService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Brak użytkowników.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email ?? 'Brak e-maila',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: user.roles
                            .map(
                              (r) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(r).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRoleColor(r).withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  r,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _getRoleColor(r),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit_roles') {
                        _showEditRolesDialog(user, apiService);
                      }
                      if (val == 'delete') {
                        _showDeleteConfirm(user, apiService);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit_roles',
                        child: Text('Zmień role'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Usuń konto',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(apiService),
        label: const Text('Nowy użytkownik'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddUserDialog(ApiService apiService) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    List<String> selectedRoles = ['Athlete'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj użytkownika'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Login'),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Hasło'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text('Role:'),
              Wrap(
                children: ['SuperAdmin', 'Admin', 'Trainer', 'Athlete']
                    .map(
                      (role) => CheckboxListTile(
                        title: Text(role),
                        value: selectedRoles.contains(role),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await apiService.createUser(
                    userCtrl.text,
                    passCtrl.text,
                    selectedRoles,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  setState(() {});
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRolesDialog(SlaviaUser user, ApiService apiService) {
    List<String> selectedRoles = List.from(user.roles);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edytuj role: ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['SuperAdmin', 'Admin', 'Trainer', 'Athlete']
                .map(
                  (role) => CheckboxListTile(
                    title: Text(role),
                    value: selectedRoles.contains(role),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedRoles.add(role);
                        } else {
                          selectedRoles.remove(role);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await apiService.updateUserRoles(user.id, selectedRoles);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  setState(() {});
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(SlaviaUser user, ApiService apiService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń użytkownika'),
        content: Text(
          'Czy na pewno chcesz usunąć użytkownika ${user.username}? Tej operacji nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await apiService.deleteUser(user.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                setState(() {});
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
              }
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Colors.purple;
      case 'Admin':
        return Colors.blue;
      case 'Trainer':
        return Colors.green;
      case 'Athlete':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
