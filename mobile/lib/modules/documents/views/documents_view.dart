import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/document_model.dart';
import '../controllers/documents_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/document_row.dart';
import '../widgets/upload_sheet.dart';

class DocumentsView extends GetView<DocumentsController> {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildCategoryChips(),
              Expanded(child: _buildDocumentList()),
            ],
          ),
          _buildFAB(),
          _buildUploadSheet(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 64, 20, 20),
      child: Text(
        'Documents',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          letterSpacing: -0.7,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = controller.categories[i];
            return Obx(
              () => CategoryChip(
                category: cat,
                isActive: controller.selectedCategory.value == cat,
                onTap: () => controller.selectCategory(cat),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    return Obx(() {
      final docs = controller.documents;
      if (docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.text3,
              ),
              const SizedBox(height: 12),
              const Text(
                'Aucun document',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.text2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // Group by month
      final grouped = <String, List<DocumentModel>>{};
      for (final doc in docs) {
        final key = _monthYear(doc.uploadedAt);
        grouped.putIfAbsent(key, () => []).add(doc);
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: grouped.length,
        itemBuilder: (_, gi) {
          final month = grouped.keys.elementAt(gi);
          final group = grouped[month]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${group.length} pièce${group.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < group.length; i++)
                      DocumentRow(
                        doc: group[i],
                        isLast: i == group.length - 1,
                        onTap: () => _showDocumentPreview(group[i]),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildFAB() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: controller.showUploadSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 26, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUploadSheet(BuildContext context) {
    return Obx(() {
      if (!controller.isUploadSheetVisible.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: controller.hideUploadSheet,
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: UploadSheet(
                onCamera: controller.pickFromCamera,
                onGallery: controller.pickFromGallery,
                onFile: controller.pickFile,
                onClose: controller.hideUploadSheet,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showDocumentPreview(DocumentModel doc) {
    // Navigate to document detail — placeholder
    Get.snackbar(
      doc.name,
      doc.categoryLabel,
      backgroundColor: AppColors.card,
      colorText: AppColors.text,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  String _monthYear(DateTime d) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

