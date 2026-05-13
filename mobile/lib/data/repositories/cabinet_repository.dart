import '../services/api_client.dart';

class ClientSummary {
  final String clientId;
  final int totalDeadlines;
  final int urgentDeadlines;
  final int lateDeadlines;
  final int uploadedDocs;
  final double completionPercentage;
  final String status; // ok | attention | critique

  const ClientSummary({
    required this.clientId,
    required this.totalDeadlines,
    required this.urgentDeadlines,
    required this.lateDeadlines,
    required this.uploadedDocs,
    required this.completionPercentage,
    required this.status,
  });

  factory ClientSummary.fromMap(Map data) {
    return ClientSummary(
      clientId: (data['client_id'] ?? '').toString(),
      totalDeadlines: (data['total_deadlines'] as num?)?.toInt() ?? 0,
      urgentDeadlines: (data['urgent_deadlines'] as num?)?.toInt() ?? 0,
      lateDeadlines: (data['late_deadlines'] as num?)?.toInt() ?? 0,
      uploadedDocs: (data['uploaded_docs'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (data['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      status: (data['status'] ?? 'ok').toString(),
    );
  }
}

class CabinetDashboard {
  final int totalClients;
  final List<ClientSummary> clients;
  final DateTime generatedAt;

  const CabinetDashboard({
    required this.totalClients,
    required this.clients,
    required this.generatedAt,
  });

  factory CabinetDashboard.fromMap(Map data) {
    final list = (data['clients'] as List?) ?? const [];
    return CabinetDashboard(
      totalClients: (data['total_clients'] as num?)?.toInt() ?? 0,
      clients: list
          .whereType<Map>()
          .map(ClientSummary.fromMap)
          .toList(),
      generatedAt: DateTime.tryParse((data['generated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class CabinetAlert {
  final ClientSummary client;
  final List<Map<String, dynamic>> urgentDeadlines;

  const CabinetAlert({required this.client, required this.urgentDeadlines});

  factory CabinetAlert.fromMap(Map data) {
    final client = ClientSummary.fromMap(
      data['client'] is Map ? data['client'] as Map : const {},
    );
    final deadlines = (data['urgent_deadlines'] as List?) ?? const [];
    return CabinetAlert(
      client: client,
      urgentDeadlines:
          deadlines.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList(),
    );
  }
}

class CabinetRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CabinetDashboard> getDashboard() async {
    final data = await _api.get('/cabinet/dashboard');
    if (data is! Map) {
      throw const ApiException('Réponse tableau de bord invalide');
    }
    return CabinetDashboard.fromMap(data);
  }

  Future<ClientSummary> getClient(String clientId) async {
    final data = await _api.get('/cabinet/clients/$clientId');
    if (data is! Map) {
      throw const ApiException('Client introuvable');
    }
    return ClientSummary.fromMap(data);
  }

  Future<List<CabinetAlert>> getAlerts() async {
    final data = await _api.get('/cabinet/alerts');
    if (data is! List) return [];
    return data.whereType<Map>().map(CabinetAlert.fromMap).toList();
  }
}
