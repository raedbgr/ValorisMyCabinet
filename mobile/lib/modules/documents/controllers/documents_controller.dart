import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';

class DocumentsController extends GetxController {
  final _repo = DocumentRepository();
  final _picker = ImagePicker();

  final documents = <DocumentModel>[].obs;
  final selectedCategory = DocumentCategory.all.obs;
  final isUploadSheetVisible = false.obs;
  final isUploading = false.obs;

  final categories = [
    DocumentCategory.all,
    DocumentCategory.facture,
    DocumentCategory.kbis,
    DocumentCategory.justificatif,
    DocumentCategory.releve,
    DocumentCategory.autre,
  ];

  @override
  void onInit() {
    super.onInit();
    _loadDocuments();
  }

  void _loadDocuments() {
    documents.value = _repo.getByCategory(selectedCategory.value);
  }

  void selectCategory(DocumentCategory category) {
    selectedCategory.value = category;
    _loadDocuments();
  }

  void showUploadSheet() => isUploadSheetVisible.value = true;
  void hideUploadSheet() => isUploadSheetVisible.value = false;

  Future<void> pickFromCamera() async {
    hideUploadSheet();
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) await _processUpload(image.path, image.name);
  }

  Future<void> pickFromGallery() async {
    hideUploadSheet();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) await _processUpload(image.path, image.name);
  }

  Future<void> pickFile() async {
    hideUploadSheet();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      await _processUpload(file.path ?? '', file.name);
    }
  }

  Future<void> _processUpload(String path, String name) async {
    isUploading.value = true;

    // Create a doc with processing status
    final doc = DocumentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: DocumentCategory.autre,
      uploadedAt: DateTime.now(),
      status: DocumentStatus.processing,
    );

    await _repo.addDocument(doc);
    _loadDocuments();

    // Simulate backend classification (replace with real API call)
    await Future.delayed(const Duration(seconds: 2));

    isUploading.value = false;
    _loadDocuments();
  }

  void deleteDocument(String id) {
    _repo.deleteDocument(id);
    _loadDocuments();
  }

  List<DocumentModel> get groupedByMonth {
    return _repo.getByCategory(selectedCategory.value);
  }
}
