import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_incident_page.dart';

const _departments = <String>[
  'Produkcja',
  'Magazyn',
  'Biuro',
  'Utrzymanie ruchu',
];

const _categories = <String>[
  'BHP',
  'Jakość',
  'Wypadek',
  'Awaria',
  'Inne',
];

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

class NewIncidentPage extends StatefulWidget {
  const NewIncidentPage({super.key});

  @override
  State<NewIncidentPage> createState() => _NewIncidentPageState();
}

class _NewIncidentPageState extends State<NewIncidentPage> {
  final _form = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  String? _department;
  String? _category;
  final List<File> _photos = [];
  bool _submitting = false;

  DateTime get _now => DateTime.now();

  bool get _canPreview =>
      _department != null &&
      _descCtrl.text.trim().isNotEmpty &&
      _photos.isNotEmpty;

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x != null) setState(() => _photos.add(File(x.path)));
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickMultiImage(imageQuality: 85);
    if (x.isNotEmpty) {
      setState(() => _photos.addAll(x.map((e) => File(e.path))));
    }
  }

  void _removeAt(int index) => setState(() => _photos.removeAt(index));

  Future<void> _goPreview() async {
    if (!_form.currentState!.validate()) return;
    if (!_canPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uzupełnij dział, opis i dodaj co najmniej jedno zdjęcie.',
          ),
        ),
      );
      return;
    }

    final depName = _department!;
    final catName = _category ?? '—';
    final depId = _departmentIdByName[depName] ?? 1;
    final catId = _categoryIdByName[catName] ?? 1;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewIncidentPage(
          payload: {
            'when': _now,
            'departmentName': depName,
            'categoryName': catName,
            'departmentId': depId,
            'categoryId': catId,
            'description': _descCtrl.text.trim(),
            'photos': List<File>.from(_photos),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0E0), Color(0xFFFF8A80)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 64,
                        ),
                      ),
                      _ChipDate(when: _now),

                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Wybierz dział',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        items: _departments
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        value: _department,
                        onChanged: (v) => setState(() => _department = v),
                        validator: (v) => v == null ? 'Wybierz dział' : null,
                      ),

                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Wybierz kategorię',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        value: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Opis',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Dodaj opis' : null,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 12),
                      _PhotosGrid(
                        files: _photos,
                        onRemove: _removeAt,
                        onAddFromCamera: _pickFromCamera,
                        onAddFromGallery: _pickFromGallery,
                      ),

                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _goPreview,
                        icon: const Icon(Icons.search),
                        label: Text(_submitting ? 'Przetwarzam…' : 'Podgląd'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipDate extends StatelessWidget {
  const _ChipDate({required this.when});
  final DateTime when;

  @override
  Widget build(BuildContext context) {
    final date =
        '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';
    final time =
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text('Incydent: $date  $time'),
        avatar: const Icon(Icons.schedule),
      ),
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({
    required this.files,
    required this.onRemove,
    required this.onAddFromCamera,
    required this.onAddFromGallery,
  });

  final List<File> files;
  final void Function(int) onRemove;
  final VoidCallback onAddFromCamera;
  final VoidCallback onAddFromGallery;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (int i = 0; i < files.length; i++)
        Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                files[i],
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: () => onRemove(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      _AddTile(
        icon: Icons.photo_camera_outlined,
        label: 'Aparat',
        onTap: onAddFromCamera,
      ),
      _AddTile(
        icon: Icons.add_photo_alternate_outlined,
        label: 'Galeria',
        onTap: onAddFromGallery,
      ),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: items.take(9).toList(),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
