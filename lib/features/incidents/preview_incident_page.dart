import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'data/incident_repository.dart';
import 'models/incident.dart';


class PreviewIncidentPage extends StatefulWidget {
  const PreviewIncidentPage({super.key, this.payload, this.readOnly = false});
  final Map<String, dynamic>? payload;
  final bool readOnly;

  @override
  State<PreviewIncidentPage> createState() => _PreviewIncidentPageState();
}

class _PreviewIncidentPageState extends State<PreviewIncidentPage> {
  bool _sending = false;
  String? _error;

  Map<String, dynamic> get _data {
    final routeArgs = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    return {...?widget.payload, ...?routeArgs};
  }

  @override
  Widget build(BuildContext context) {
    final when = _data['when'] as DateTime?;
    final depName = (_data['departmentName'] ?? '—').toString();
    final catName = (_data['categoryName'] ?? '—').toString();
    final depId = (_data['departmentId'] ?? 1) as int;
    final catId = (_data['categoryId'] ?? 1) as int;
    final desc = (_data['description'] ?? '').toString();
    final photos = (_data['photos'] as List<File>? ?? const []);

    return Scaffold(
      appBar: AppBar(title: const Text('Podgląd i wysyłka')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Tile(label: 'Data', value: _fmtDateTime(when ?? DateTime.now())),
                _Tile(label: 'Dział', value: depName),
                _Tile(label: 'Kategoria', value: catName),
                const SizedBox(height: 12),
                const Text('Opis', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(desc.isEmpty ? '—' : desc),
                ),
                const SizedBox(height: 16),
                const Text('Zdjęcia', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _PhotosGrid(files: photos),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
bottomNavigationBar: Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  child: widget.readOnly
      ? FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zamknij'),
        )
      : FilledButton.icon(
          onPressed: _sending ? null : () => _send(desc, depId, catId, photos,
              when: when ?? DateTime.now(),
              depName: depName,
              catName: catName),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(_sending ? 'Wysyłam…' : 'Wyślij'),
        ),
),
    );
  }

  Future<void> _send(String desc, int depId, int catId, List<File> photos,
    {required DateTime when, required String depName, required String catName}) async {
  
    const apiBase = 'http://192.168.191.2:8080';
    final api = ApiClient(apiBase);

    final (ok, msg) = await api.createIncident(
      description: desc,
      departmentId: depId,
      categoryId: catId,
      photos: photos,
    );

    if (ok) {
    final repo = IncidentRepository.instance;
    repo.add(Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportedAt: when,
      department: depName,
      category: catName,
      description: desc,
      photos: List<File>.from(photos),
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incydent wysłany.')),
    );
    Navigator.popUntil(context, (r) => r.isFirst);
  } else {
    setState(() => _error = msg);
  }
}

  String _fmtDateTime(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  final List<File> files;
  const _PhotosGrid({required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Brak zdjęć'),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemBuilder: (context, i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(files[i], fit: BoxFit.cover),
        );
      },
    );
  }
}
