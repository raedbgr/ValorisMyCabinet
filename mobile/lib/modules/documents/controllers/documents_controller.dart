import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/services/api_client.dart';
import '../../auth/controllers/auth_controller.dart';

class DocumentsController extends GetxController {
  final _repo = DocumentRepository();
  final _picker = ImagePicker();

  final documents = <DocumentModel>[].obs;
  final selectedCategory = DocumentCategory.all.obs;
  final isUploadSheetVisible = false.obs;
  final isUploading = false.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final categories = [
    DocumentCategory.all,
    DocumentCategory.facture,
    DocumentCategory.kbis,
    DocumentCategory.justificatif,
    DocumentCategory.releve,
    DocumentCategory.autre,
  ];

  String get _clientId {
    if (Get.isRegistered<AuthController>()) {
      final u = Get.find<AuthController>().currentUser.value;
      if (u != null) return u.id;
    }
    return _repo.defaultClientId;
  }

  @override
  void onInit() {
    super.onInit();
    refreshDocuments();
  }

  Future<void> refreshDocuments() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.fetchAll(_clientId);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erreur inattendue';
    } finally {
      _applyFilter();
      isLoading.value = false;
    }
  }

  void _applyFilter() {
    documents.value = _repo.getByCategory(selectedCategory.value);
  }

  void selectCategory(DocumentCategory category) {
    selectedCategory.value = category;
    _applyFilter();
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
      if ((file.path ?? '').isEmpty) return;
      await _processUpload(file.path!, file.name);
    }
  }

  Future<void> _processUpload(String path, String name) async {
    isUploading.value = true;
    try {
      await _repo.uploadDocument(
        clientId: _clientId,
        filePath: path,
        filename: name,
        category: selectedCategory.value == DocumentCategory.all
            ? _guessCategory(name)
            : selectedCategory.value,
      );
      _applyFilter();
      Get.snackbar(
        'Document téléversé',
        name,
        backgroundColor: AppColors.card,
        colorText: AppColors.text,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

      // Trigger backend processing in background
      _repo.processDocument(clientId: _clientId, filename: name).catchError(
            (_) => null,
          );
    } on ApiException catch (e) {
      Get.snackbar(
        'Erreur de téléversement',
        e.message,
        backgroundColor: AppColors.card,
        colorText: AppColors.text,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isUploading.value = false;
      // Refresh from server to get the canonical state
      await refreshDocuments();
    }
  }

  DocumentCategory _guessCategory(String name) {
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

  Future<void> deleteDocument(String id) async {
    try {
      await _repo.deleteDocument(clientId: _clientId, id: id);
    } on ApiException catch (e) {
      Get.snackbar(
        'Suppression échouée',
        e.message,
        backgroundColor: AppColors.card,
        colorText: AppColors.text,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _applyFilter();
    }
  }

  List<DocumentModel> get groupedByMonth {
    return _repo.getByCategory(selectedCategory.value);
  }
}
