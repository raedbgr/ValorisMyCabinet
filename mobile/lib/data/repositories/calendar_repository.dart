import '../models/deadline_model.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';

class CalendarRepository {
  final ApiClient _api = ApiClient.instance;
  final List<DeadlineModel> _cache = [];

  String get defaultClientId => ApiConfig.defaultClientId;

  List<DeadlineModel> getAll() => List.unmodifiable(_cache);

  List<DeadlineModel> getByStatus(DeadlineStatus status) =>
      _cache.where((d) => d.status == status).toList();

  DeadlineModel? getNext() {
    final upcoming = _cache
        .where((d) =>
            d.status == DeadlineStatus.urgent ||
            d.status == DeadlineStatus.upcoming)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  DeadlineModel? getById(String id) {
    try {
      return _cache.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<DeadlineModel>> fetchAll(String clientId) async {
    final data = await _api.get('/deadlines/$clientId');
    _cache
      ..clear()
      ..addAll(_parseList(data));
    return getAll();
  }

  Future<List<DeadlineModel>> fetchUrgent(String clientId) async {
    final data = await _api.get('/deadlines/$clientId/urgent');
    return _parseList(data);
  }

  Future<DeadlineModel> createDeadline({
    required String clientId,
    required String label,
    required DateTime dueDate,
    required String type,
  }) async {
    final iso =
        '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    final data = await _api.post('/deadlines/', body: {
      'client_id': clientId,
      'label': label,
      'due_date': iso,
      'type': type,
    });
    final created = _parseOne(data);
    if (created != null) _cache.add(created);
    return created!;
  }

  Future<List<DeadlineModel>> seedDeadlines(String clientId) async {
    final data = await _api.post('/deadlines/seed/$clientId');
    return _parseList(data);
  }

  List<DeadlineModel> _parseList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map(_parseOne)
        .whereType<DeadlineModel>()
        .toList();
  }

  DeadlineModel? _parseOne(dynamic raw) {
    if (raw is! Map) return null;
    final id = (raw['id'] ?? '').toString();
    final label = (raw['label'] ?? '').toString();
    final type = (raw['type'] ?? 'autre').toString();
    final dueStr = (raw['due_date'] ?? '').toString();
    final due = DateTime.tryParse(dueStr);
    if (id.isEmpty || due == null) return null;

    final statusStr = (raw['status'] ?? 'upcoming').toString();
    final status = _statusFromString(statusStr);

    return DeadlineModel(
      id: id,
      code: type,
      title: label,
      period: _periodForDate(due),
      dueDate: due,
      status: status,
      missingDocs: 0,
    );
  }

  DeadlineStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'urgent':
        return DeadlineStatus.urgent;
      case 'late':
        return DeadlineStatus.late;
      case 'done':
      case 'complete':
        return DeadlineStatus.complete;
      case 'upcoming':
      default:
        return DeadlineStatus.upcoming;
    }
  }

  String _periodForDate(DateTime d) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    final m = months[(d.month - 1).clamp(0, 11)];
    return 'Période — $m ${d.year}';
  }
}
