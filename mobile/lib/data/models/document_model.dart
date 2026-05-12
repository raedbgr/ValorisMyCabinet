enum DocumentCategory { all, facture, kbis, justificatif, releve, autre }

enum DocumentStatus { processing, ready }

class DocumentModel {
  final String id;
  final String name;
  final DocumentCategory category;
  final DateTime uploadedAt;
  final DocumentStatus status;
  final String? downloadUrl;
  final int? sizeBytes;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.uploadedAt,
    this.status = DocumentStatus.ready,
    this.downloadUrl,
    this.sizeBytes,
  });

  String get categoryLabel {
    switch (category) {
      case DocumentCategory.facture:
        return 'Facture';
      case DocumentCategory.kbis:
        return 'K-bis';
      case DocumentCategory.justificatif:
        return 'Justificatif';
      case DocumentCategory.releve:
        return 'Relevé bancaire';
      case DocumentCategory.autre:
        return 'Autre';
      case DocumentCategory.all:
        return 'Tous';
    }
  }

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      name.toLowerCase().endsWith('.jpg') ||
      name.toLowerCase().endsWith('.jpeg') ||
      name.toLowerCase().endsWith('.png');
}
