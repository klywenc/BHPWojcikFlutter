import 'package:flutter/foundation.dart';
import '../models/incident.dart';

class IncidentRepository {
  IncidentRepository._();
  static final IncidentRepository instance = IncidentRepository._();

  final ValueNotifier<List<Incident>> list =
      ValueNotifier<List<Incident>>(<Incident>[]);

  List<Incident> get items => List.unmodifiable(list.value);

  void add(Incident incident) {
    final copy = List<Incident>.from(list.value);
    copy.insert(0, incident);
    list.value = copy;
  }

  void remove(String id) {
    final copy = List<Incident>.from(list.value)..removeWhere((e) => e.id == id);
    list.value = copy;
  }

  void clear() => list.value = <Incident>[];
}
