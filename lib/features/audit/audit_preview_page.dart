import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../incidents/preview_incident_page.dart';

const _departmentIdByName = <String, int>{
  'Produkcja': 1,
  'Magazyn': 2,
  'Biuro': 3,
  'Utrzymanie ruchu': 4,
};
const _categoryIdByName = <String, int>{
  'BHP': 1,
  'Jakość': 2,
  'Wypadek': 3,
  'Awaria': 4,
  'Inne': 5,
};

class AuditFinding {
  final String tempId;
  final DateTime when;
  final String departmentName;
  final int departmentId;
  final String categoryName;
  final int categoryId;
  final String description;
  final List<File> photos;

  AuditFinding({
    required this.tempId,
    required this.when,
    required this.departmentName,
    required this.departmentId,
    required this.categoryName,
    required this.categoryId,
    required this.description,
    required this.photos,
  });
}

class AuditSession {
  AuditSession._();
  static final AuditSession instance = AuditSession._();

  final List<AuditFinding> items = [];

  void add(AuditFinding f) => items.add(f);
  void remove(String tempId) => items.removeWhere((e) => e.tempId == tempId);
  void clear() => items.clear();
}

class AuditPreviewPage extends StatefulWidget {
  const AuditPreviewPage({super.key});
  @override
  State<AuditPreviewPage> createState() => _AuditPreviewPageState();
}

class _AuditPreviewPageState extends State<AuditPreviewPage> {
  final _session = AuditSession.instance;

  bool _sending = false;
  String? _error;
  String? _apiBase;

  bool _absorbed = false;

  Color get _brandDark  => const Color(0xFFC62828);
  Color get _brandLight => const Color(0xFFFF8A80);
  Color get _brandPale  => const Color(0xFFFFE0E0);

  @override
  void initState() {
    super.initState();
    _loadBase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_absorbed) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _absorbPayloadMap(Map<String, dynamic>.from(args));
    }
    _absorbed = true;
  }

  Future<void> _loadBase() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiBase = sp.getString('apiBase') ?? '');
  }

  void _absorbPayloadMap(Map<String, dynamic> p) {
    if (p.isEmpty) return;
    final when    = (p['when'] as DateTime?) ?? DateTime.now();
    final depName = (p['departmentName'] ?? '').toString();
    final catName = (p['categoryName'] ?? '').toString();
    final desc    = (p['description'] ?? '').toString();
    final photos  = (p['photos'] as List?)?.whereType<File>().toList() ?? <File>[];

    final depId = _departmentIdByName[depName] ?? 1;
    final catId = _categoryIdByName[catName] ?? 1;

    _session.add(AuditFinding(
      tempId: DateTime.now().microsecondsSinceEpoch.toString(),
      when: when,
      departmentName: depName,
      departmentId: depId,
      categoryName: catName,
      categoryId: catId,
      description: desc,
      photos: photos,
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _session.items;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandPale, _brandLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset('assets/images/logo.png', height: 28),
              ),
              const Text('Audyt — podgląd'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _FindingTile(
                              f: items[i],
                              onPreview: () => _openFindingPreview(items[i]),
                              onDelete: () {
                                setState(() => _session.remove(items[i].tempId));
                              },
                            ),
                          ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sending ? null : _addNextFinding,
                          icon: const Icon(Icons.add),
                          label: const Text('Dodaj kolejne znalezisko'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandDark,
                          ),
                          onPressed: (_sending || items.isEmpty) ? null : _sendAll,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_sending ? 'Wysyłam…' : 'Wyślij wszystko (${items.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addNextFinding() {
    Navigator.of(context).pushNamed('/audit/new');
  }

  void _openFindingPreview(AuditFinding f) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewIncidentPage(
          readOnly: true,
          payload: {
            'when': f.when,
            'departmentName': f.departmentName,
            'categoryName': f.categoryName,
            'description': f.description,
            'photos': f.photos,
          },
        ),
      ),
    );
  }

  Future<void> _sendAll() async {
    final items = List<AuditFinding>.from(_session.items);
    if (_apiBase == null || _apiBase!.isEmpty) {
      setState(() => _error = 'Brak adresu API (apiBase). Zaloguj się ponownie.');
      return;
    }

    setState(() { _sending = true; _error = null; });

    final api = ApiClient(_apiBase!);
    int okCount = 0;
    final List<String> errors = [];

    for (final f in items) {
      final (ok, msg) = await api.createIncident(
        description: f.description,
        departmentId: f.departmentId,
        categoryId: f.categoryId,
        photos: f.photos,
      );
      if (ok) {
        okCount++;
      } else {
        errors.add(msg);
      }
      if (!mounted) return;
      setState(() {});
    }

    setState(() { _sending = false; });

    if (errors.isEmpty) {
      _session.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wysłano ${okCount}/ ${items.length} znalezisk.')),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      setState(() {
        _error = 'Niepowodzenia: ${errors.length}\n${errors.take(3).join('\n')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wysłano ${okCount}/${items.length}. ${errors.length} z błędami.')),
      );
    }
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({
    required this.f,
    required this.onPreview,
    required this.onDelete,
  });

  final AuditFinding f;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(_titleFor(f.description)),
        subtitle: Text('${_fmtDate(f.when)} • ${f.departmentName} • ${f.categoryName}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Podgląd',
              icon: const Icon(Icons.visibility_outlined),
              onPressed: onPreview,
            ),
            IconButton(
              tooltip: 'Usuń',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onPreview,
      ),
    );
  }

  String _titleFor(String description) {
    final t = description.trim();
    if (t.isEmpty) return 'Znalezisko ${_fmtDate(f.when)}';
    final first = t.split('\n').first;
    return first.length > 50 ? '${first.substring(0, 50)}…' : first;
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.playlist_add_outlined, size: 48),
          SizedBox(height: 8),
          Text('Brak znalezisk w audycie.\nDodaj pierwsze, aby rozpocząć.'),
        ],
      ),
    );
  }
}
