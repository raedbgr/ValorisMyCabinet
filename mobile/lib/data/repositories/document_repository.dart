import '../models/document_model.dart';

class DocumentRepository {
  // Mock data — replace with Firebase Storage + Firestore calls
  final List<DocumentModel> _documents = [
    DocumentModel(
      id: '1',
      name: 'Facture_Boulangerie_08-2026.pdf',
      category: DocumentCategory.facture,
      uploadedAt: DateTime.now(),
    ),
    DocumentModel(
      id: '2',
      name: 'Recu_courses_03-08.jpg',
      category: DocumentCategory.justificatif,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: DocumentStatus.processing,
    ),
    DocumentModel(
      id: '3',
      name: 'Releve_LCL_juillet.pdf',
      category: DocumentCategory.releve,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DocumentModel(
      id: '4',
      name: 'Facture_Farine_Moulin.pdf',
      category: DocumentCategory.facture,
      uploadedAt: DateTime(2026, 7, 28),
    ),
    DocumentModel(
      id: '5',
      name: 'Kbis_2026.pdf',
      category: DocumentCategory.kbis,
      uploadedAt: DateTime(2026, 7, 22),
    ),
    DocumentModel(
      id: '6',
      name: 'Facture_EDF_juillet.pdf',
      category: DocumentCategory.facture,
      uploadedAt: DateTime(2026, 7, 15),
    ),
  ];

  List<DocumentModel> getAll() => List.unmodifiable(_documents);

  List<DocumentModel> getByCategory(DocumentCategory category) {
    if (category == DocumentCategory.all) return getAll();
    return _documents.where((d) => d.category == category).toList();
  }

  List<DocumentModel> getRecent({int limit = 3}) {
    final sorted = [..._documents]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return sorted.take(limit).toList();
  }

  Future<void> addDocument(DocumentModel doc) async {
    _documents.insert(0, doc);
  }

  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
  }

  int get totalCount => _documents.length;
}
