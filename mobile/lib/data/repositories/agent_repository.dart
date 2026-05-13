import '../services/api_client.dart';

class AgentCheckResult {
  final bool shouldRemind;
  final String? reminderMessage;
  final String urgency;
  final String missingDocsSummary;
  final String clientId;
  final int urgentDeadlinesCount;
  final int missingDocsCount;
  final DateTime checkedAt;

  const AgentCheckResult({
    required this.shouldRemind,
    required this.reminderMessage,
    required this.urgency,
    required this.missingDocsSummary,
    required this.clientId,
    required this.urgentDeadlinesCount,
    required this.missingDocsCount,
    required this.checkedAt,
  });

  factory AgentCheckResult.fromMap(Map data) {
    return AgentCheckResult(
      shouldRemind: data['should_remind'] == true,
      reminderMessage: data['reminder_message']?.toString(),
      urgency: (data['urgency'] ?? 'medium').toString(),
      missingDocsSummary: (data['missing_docs_summary'] ?? '').toString(),
      clientId: (data['client_id'] ?? '').toString(),
      urgentDeadlinesCount:
          (data['urgent_deadlines_count'] as num?)?.toInt() ?? 0,
      missingDocsCount: (data['missing_docs_count'] as num?)?.toInt() ?? 0,
      checkedAt: DateTime.tryParse((data['checked_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ReminderEntry {
  final String id;
  final String clientId;
  final String message;
  final String urgency;
  final DateTime sentAt;
  final bool auto;

  const ReminderEntry({
    required this.id,
    required this.clientId,
    required this.message,
    required this.urgency,
    required this.sentAt,
    required this.auto,
  });

  factory ReminderEntry.fromMap(Map data) {
    return ReminderEntry(
      id: (data['id'] ?? '').toString(),
      clientId: (data['client_id'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      urgency: (data['urgency'] ?? 'medium').toString(),
      sentAt: DateTime.tryParse((data['sent_at'] ?? '').toString()) ??
          DateTime.now(),
      auto: data['auto'] == true,
    );
  }
}

class AgentRepository {
  final ApiClient _api = ApiClient.instance;

  Future<AgentCheckResult> check(String clientId) async {
    final data = await _api.get('/agent/check/$clientId');
    if (data is! Map) {
      throw const ApiException('Réponse agent invalide');
    }
    return AgentCheckResult.fromMap(data);
  }

  Future<AgentCheckResult> remind(String clientId) async {
    final data = await _api.post('/agent/remind/$clientId');
    if (data is! Map) {
      throw const ApiException('Réponse agent invalide');
    }
    return AgentCheckResult.fromMap(data);
  }

  Future<AgentCheckResult> analyze({
    required String clientName,
    required List<Map<String, dynamic>> deadlines,
    required List<Map<String, dynamic>> missingDocuments,
  }) async {
    final data = await _api.post('/agent/analyze', body: {
      'client_name': clientName,
      'deadlines': deadlines,
      'missing_documents': missingDocuments,
    });
    if (data is! Map) {
      throw const ApiException('Réponse agent invalide');
    }
    return AgentCheckResult(
      shouldRemind: data['should_remind'] == true,
      reminderMessage: data['reminder_message']?.toString(),
      urgency: (data['urgency'] ?? 'medium').toString(),
      missingDocsSummary: (data['missing_docs_summary'] ?? '').toString(),
      clientId: clientName,
      urgentDeadlinesCount: deadlines.length,
      missingDocsCount: missingDocuments.length,
      checkedAt: DateTime.now(),
    );
  }

  Future<List<ReminderEntry>> getReminders(String clientId) async {
    final data = await _api.get('/agent/reminders/$clientId');
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map(ReminderEntry.fromMap)
        .toList();
  }
}
