import 'package:flutter/material.dart';
import 'data/incident_repository.dart';
import 'models/incident.dart';
import 'preview_incident_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = IncidentRepository.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Historia raportów')),
      body: ValueListenableBuilder<List<Incident>>(
        valueListenable: repo.list,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(child: Text('Brak zapisanych raportów'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final it = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_titleFor(it)),
                  subtitle: Text(
                    '${_fmtDate(it.reportedAt)} • ${it.department} • ${it.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Podgląd',
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _openPreview(context, it),
                      ),
                      IconButton(
                        tooltip: 'Usuń z historii',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.remove(it.id),
                      ),
                    ],
                  ),
                  onTap: () => _openPreview(context, it),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openPreview(BuildContext context, Incident it) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewIncidentPage(
          readOnly: true,
          payload: {
            'when': it.reportedAt,
            'departmentName': it.department,
            'categoryName': it.category,
            'description': it.description,
            'photos': it.photos,
          },
        ),
      ),
    );
  }

  String _titleFor(Incident i) {
    final t = i.description.trim();
    if (t.isEmpty) return 'Raport ${_fmtDate(i.reportedAt)}';
    final first = t.split('\n').first;
    return first.length > 50 ? '${first.substring(0, 50)}…' : first;
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
