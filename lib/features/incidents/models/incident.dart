import 'dart:io';

class Incident {
  final String id;
  final DateTime reportedAt;
  final String department;
  final String category;
  final String description;
  final List<File> photos;

  Incident({
    required this.id,
    required this.reportedAt,
    required this.department,
    required this.category,
    required this.description,
    required this.photos,
  });
}
