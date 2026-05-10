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

class _AthletePortalScreenState extends State<AthletePortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _refreshResults = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final api = Provider.of<ApiService>(context, listen: false);
    final athleteId = auth.user?.athleteId;
    final primary = Theme.of(context).colorScheme.primary;

    if (athleteId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel Zawodnika')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Konto nie jest powiązane z profilem zawodnika.',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Panel Zawodnika', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
              background: _buildHeroBackground(athleteId, api, primary),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
                indicatorColor: primary,
                labelColor: primary,
                tabs: const [
                  Tab(text: 'Przegląd'),
                  Tab(text: 'Starty'),
                  Tab(text: 'Treningi'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(athleteId: athleteId, api: api, primary: primary),
            _ResultsTab(athleteId: athleteId, api: api, primary: primary, kind: 'competition', refresh: _refreshResults,
              onAdd: () => _showAddResultDialog(athleteId, api, 'competition')),
            _ResultsTab(athleteId: athleteId, api: api, primary: primary, kind: 'training', refresh: _refreshResults,
              onAdd: () => _showAddResultDialog(athleteId, api, 'training')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddResultDialog(athleteId, api, _tabController.index == 2 ? 'training' : 'competition'),
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 2 ? 'Dodaj trening' : 'Zgłoś start'),
      ),
    );
  }

  Widget _buildHeroBackground(String athleteId, ApiService api, Color primary) {
    return FutureBuilder<Athlete>(
      future: api.getAthlete(athleteId),
      builder: (context, snap) {
        final a = snap.data;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.6), Theme.of(context).colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: a?.imageUrl != null ? NetworkImage(a!.imageUrl!) : null,
                    child: a?.imageUrl == null
                        ? Text(a?.fullName.substring(0, 1) ?? '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(a?.fullName ?? '...', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                        if (a?.weightCategory != null)
                          Text('${a!.weightCategory} · ${a.birthYear ?? ''}',
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddResultDialog(String athleteId, ApiService api, String defaultKind) {
    final snatchCtrl = TextEditingController();
    final cjCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String kind = defaultKind;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Nowy wpis', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                // Type selector
                Row(
                  children: [
                    _TypeChip(label: 'Zawody', value: 'competition', selected: kind, onTap: (v) => setSheet(() => kind = v)),
                    const SizedBox(width: 10),
                    _TypeChip(label: 'Trening', value: 'training', selected: kind, onTap: (v) => setSheet(() => kind = v)),
                  ],
                ),
                const SizedBox(height: 16),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2010),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setSheet(() => selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text('${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                          style: GoogleFonts.outfit(fontSize: 15)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Snatch + CJ row
                Row(
                  children: [
                    Expanded(child: _ResultField(ctrl: snatchCtrl, label: 'Rwanie (kg)')),
                    const SizedBox(width: 12),
                    Expanded(child: _ResultField(ctrl: cjCtrl, label: 'Podrzut (kg)')),
                  ],
                ),
                const SizedBox(height: 12),

                if (kind == 'competition')
                  TextField(
                    controller: locCtrl,
                    decoration: InputDecoration(
                      labelText: 'Lokalizacja',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (kind == 'training') ...[
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notatki z treningu',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      final s = double.tryParse(snatchCtrl.text) ?? 0;
                      final c = double.tryParse(cjCtrl.text) ?? 0;
                      if (s == 0 && c == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Podaj co najmniej jeden wynik')));
                        return;
                      }
                      try {
                        await api.submitResult(
                          athleteId: athleteId,
                          date: selectedDate.toIso8601String().substring(0, 10),
                          kind: kind,
                          location: locCtrl.text.isEmpty ? null : locCtrl.text,
                          snatch: s > 0 ? s : null,
                          cleanAndJerk: c > 0 ? c : null,
                          total: s + c,
                        );
                        Navigator.pop(ctx);
                        setState(() => _refreshResults = !_refreshResults);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wynik zgłoszony ✓')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd: $e')));
                      }
                    },
                    child: Text('Zgłoś wynik', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _TypeChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : primary,
        )),
      ),
    );
  }
}

class _ResultField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _ResultField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixText: 'kg',
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String athleteId;
  final ApiService api;
  final Color primary;
  const _OverviewTab({required this.athleteId, required this.api, required this.primary});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Athlete>(
      future: api.getAthlete(athleteId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final a = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KPI cards
            Row(children: [
              Expanded(child: _KpiCard(label: 'Rwanie', value: a.bestSnatchKg != null ? '${a.bestSnatchKg} kg' : '—', icon: Icons.bolt, color: Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(label: 'Podrzut', value: a.bestCleanJerkKg != null ? '${a.bestCleanJerkKg} kg' : '—', icon: Icons.flash_on, color: Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(label: 'Dwubój', value: a.totalKg != null ? '${a.totalKg} kg' : '—', icon: Icons.emoji_events, color: Colors.amber)),
            ]),
            const SizedBox(height: 20),
            // Bio card
            if (a.bio != null && a.bio!.isNotEmpty) ...[
              _SectionHeader(title: 'O mnie'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withOpacity(0.1)),
                ),
                child: Text(a.bio!, style: GoogleFonts.outfit(fontSize: 14, height: 1.6)),
              ),
              const SizedBox(height: 16),
            ],
            // Stats table
            _SectionHeader(title: 'Dane zawodnika'),
            _InfoTable(rows: [
              if (a.birthYear != null) _InfoRow('Rocznik', '${a.birthYear}'),
              if (a.weightCategory != null) _InfoRow('Kategoria wagowa', a.weightCategory!),
              if (a.bodyweight != null) _InfoRow('Waga ciała', '${a.bodyweight} kg'),
              if (a.gender != null) _InfoRow('Płeć', a.gender == 'M' ? 'Mężczyzna' : 'Kobieta'),
              _InfoRow('Status', a.isActive ? 'Aktywny' : 'Nieaktywny'),
            ]),
          ],
        );
      },
    );
  }
}

// ─── Results Tab ───────────────────────────────────────────────────────────────

class _ResultsTab extends StatelessWidget {
  final String athleteId;
  final ApiService api;
  final Color primary;
  final String kind;
  final bool refresh;
  final VoidCallback onAdd;
  const _ResultsTab({required this.athleteId, required this.api, required this.primary, required this.kind, required this.refresh, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CompetitionResult>>(
      key: ValueKey('$kind-$refresh'),
      future: api.getAthleteResults(athleteId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final results = all.where((r) => r.kind == kind).toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(kind == 'competition' ? Icons.emoji_events_outlined : Icons.fitness_center_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(kind == 'competition' ? 'Brak zgłoszonych startów' : 'Brak wpisów treningowych',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(kind == 'competition' ? 'Zgłoś start' : 'Dodaj trening'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            final statusColor = r.status == 'Approved'
                ? Colors.green
                : r.status == 'Rejected'
                    ? Colors.red
                    : Colors.orange;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.date.substring(0, 10), style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            r.status == 'Approved' ? 'Zatwierdzone' : r.status == 'Rejected' ? 'Odrzucone' : 'Oczekuje',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    if (r.location != null && r.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(r.location!, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500])),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (r.snatch != null) _ResultBadge(label: 'Rwanie', value: '${r.snatch} kg', color: Colors.orange),
                        if (r.snatch != null && r.cleanAndJerk != null) const SizedBox(width: 8),
                        if (r.cleanAndJerk != null) _ResultBadge(label: 'Podrzut', value: '${r.cleanAndJerk} kg', color: Colors.blue),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Total', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
                            Text('${r.total} kg', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: primary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: color.withOpacity(0.8))),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow {
  final String label, value;
  const _InfoRow(this.label, this.value);
}

class _InfoTable extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.value.label, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600])),
                Text(e.value.value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
