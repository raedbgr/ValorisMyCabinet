import '../models/deadline_model.dart';

class CalendarRepository {
  // Mock data — replace with Firestore calls
  final List<DeadlineModel> _deadlines = [
    DeadlineModel(
      id: 'tva-07-2026',
      code: 'TVA',
      title: 'Déclaration TVA',
      period: 'Période — Juillet 2026',
      dueDate: DateTime(2026, 8, 20),
      status: DeadlineStatus.urgent,
      missingDocs: 2,
      requiredDocTypes: ['Factures juillet', 'Relevé bancaire juillet'],
    ),
    DeadlineModel(
      id: 'dsn-07-2026',
      code: 'DSN',
      title: 'DSN mensuelle',
      period: 'Période — Juillet 2026',
      dueDate: DateTime(2026, 9, 5),
      status: DeadlineStatus.upcoming,
      missingDocs: 0,
    ),
    DeadlineModel(
      id: 'is-3-2026',
      code: 'IS',
      title: "Acompte d'impôt sur les sociétés",
      period: '3ème acompte 2026',
      dueDate: DateTime(2026, 9, 15),
      status: DeadlineStatus.upcoming,
      missingDocs: 1,
      requiredDocTypes: ['Bilan prévisionnel'],
    ),
    DeadlineModel(
      id: 'cfe-1-2026',
      code: 'CFE',
      title: 'Acompte de CFE',
      period: '1er acompte 2026',
      dueDate: DateTime(2026, 6, 15),
      status: DeadlineStatus.late,
      missingDocs: 1,
    ),
    DeadlineModel(
      id: 'tva-06-2026',
      code: 'TVA',
      title: 'Déclaration TVA',
      period: 'Période — Juin 2026',
      dueDate: DateTime(2026, 7, 20),
      status: DeadlineStatus.complete,
      missingDocs: 0,
    ),
  ];

  List<DeadlineModel> getAll() => List.unmodifiable(_deadlines);

  List<DeadlineModel> getByStatus(DeadlineStatus status) =>
      _deadlines.where((d) => d.status == status).toList();

  DeadlineModel? getNext() {
    final upcoming = _deadlines
        .where((d) =>
            d.status == DeadlineStatus.urgent ||
            d.status == DeadlineStatus.upcoming)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  DeadlineModel? getById(String id) {
    try {
      return _deadlines.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
