import '../models/document_model.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';

class DocumentRepository {
  final ApiClient _api = ApiClient.instance;
  final List<DocumentModel> _cache = [];

  String get defaultClientId => ApiConfig.defaultClientId;

  List<DocumentModel> getAll() => List.unmodifiable(_cache);

  List<DocumentModel> getByCategory(DocumentCategory category) {
    if (category == DocumentCategory.all) return getAll();
    return _cache.where((d) => d.category == category).toList();
  }

  List<DocumentModel> getRecent({int limit = 3}) {
    final sorted = [..._cache]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return sorted.take(limit).toList();
  }

  int get totalCount => _cache.length;

  Future<List<DocumentModel>> fetchAll(String clientId) async {
    final data = await _api.get('/documents/$clientId');
    if (data is! List) {
      _cache.clear();
      return getAll();
    }

    final docs = <DocumentModel>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final name = (entry['name'] ?? '').toString();
      if (name.isEmpty) continue;
      final path = (entry['path'] ?? '').toString();
      docs.add(DocumentModel(
        id: path.isNotEmpty ? path : name,
        name: _displayName(name),
        category: _inferCategory(name),
        uploadedAt: _inferDate(name),
        status: DocumentStatus.ready,
        downloadUrl: path,
      ));
    }

    _cache
      ..clear()
      ..addAll(docs);
    return getAll();
  }

  Future<DocumentModel> uploadDocument({
    required String clientId,
    required String filePath,
    required String filename,
    required DocumentCategory category,
  }) async {
    final data = await _api.uploadFile(
      '/documents/upload',
      filePath: filePath,
      filename: filename,
      fields: {
        'client_id': clientId,
        'document_type': _categoryToType(category),
      },
    );

    if (data is! Map) {
      throw const ApiException('Réponse de téléversement invalide');
    }

    final fileUrl = (data['file_url'] ?? '').toString();
    final doc = DocumentModel(
      id: fileUrl.isNotEmpty ? fileUrl : (data['id'] ?? filename).toString(),
      name: (data['name'] ?? filename).toString(),
      category: _categoryFromType((data['type'] ?? '').toString()),
      uploadedAt: DateTime.tryParse((data['uploaded_at'] ?? '').toString()) ??
          DateTime.now(),
      status: (data['status'] ?? '').toString() == 'pending'
          ? DocumentStatus.processing
          : DocumentStatus.ready,
      downloadUrl: fileUrl,
    );

    _cache.insert(0, doc);
    return doc;
  }

  Future<Map<String, dynamic>?> processDocument({
    required String clientId,
    required String filename,
  }) async {
    final data =
        await _api.post('/documents/process', body: {
      'client_id': clientId,
      'filename': filename,
    });
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>?> processAll(String clientId) async {
    final data = await _api.post('/documents/process-all/$clientId');
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>?> getMetadata({
    required String clientId,
    required String filename,
  }) async {
    try {
      final data = await _api.get('/documents/$clientId/$filename/metadata');
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> deleteDocument({
    required String clientId,
    required String id,
  }) async {
    final filename = _filenameFromId(id);
    if (filename != null) {
      await _api.delete('/documents/$clientId/$filename');
    }
    _cache.removeWhere((d) => d.id == id);
  }

  String? _filenameFromId(String id) {
    if (id.isEmpty) return null;
    final parts = id.split('/');
    return parts.isEmpty ? id : parts.last;
  }

  String _displayName(String storedName) {
    final hyphenIndex = storedName.indexOf('_');
    if (hyphenIndex > 0 && hyphenIndex < 40) {
      return storedName.substring(hyphenIndex + 1);
    }
    return storedName;
  }

  DateTime _inferDate(String name) {
    final lower = name.toLowerCase();
    final match = RegExp(r'(\d{4})[-_](\d{2})').firstMatch(lower);
    if (match != null) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      if (year != null && month != null && month >= 1 && month <= 12) {
        return DateTime(year, month, 1);
      }
    }
    return DateTime.now();
  }

  DocumentCategory _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('facture')) return DocumentCategory.facture;
    if (lower.contains('kbis')) return DocumentCategory.kbis;
    if (lower.contains('releve') || lower.contains('relevé')) {
      return DocumentCategory.releve;
    }
    if (lower.contains('justificatif') || lower.contains('recu')) {
      return DocumentCategory.justificatif;
    }
    return DocumentCategory.autre;
  }

  String _categoryToType(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.facture:
        return 'facture';
      case DocumentCategory.kbis:
        return 'kbis';
      case DocumentCategory.justificatif:
        return 'justificatif';
      case DocumentCategory.releve:
        return 'releve_bancaire';
      case DocumentCategory.autre:
      case DocumentCategory.all:
        return 'autre';
    }
  }

  DocumentCategory _categoryFromType(String type) {
    switch (type) {
      case 'facture':
        return DocumentCategory.facture;
      case 'kbis':
        return DocumentCategory.kbis;
      case 'justificatif':
        return DocumentCategory.justificatif;
      case 'releve_bancaire':
        return DocumentCategory.releve;
      default:
        return DocumentCategory.autre;
    }
  }
}
