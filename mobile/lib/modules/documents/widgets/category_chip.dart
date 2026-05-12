import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/document_model.dart';

class CategoryChip extends StatelessWidget {
  final DocumentCategory category;
  final bool isActive;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  String get _label {
    switch (category) {
      case DocumentCategory.all:
        return 'Tous';
      case DocumentCategory.facture:
        return 'Factures';
      case DocumentCategory.kbis:
        return 'K-bis';
      case DocumentCategory.justificatif:
        return 'Justificatifs';
      case DocumentCategory.releve:
        return 'Relevés bancaires';
      case DocumentCategory.autre:
        return 'Autres';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Text(
          _label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.text,
            letterSpacing: -0.1,
            height: 1,
          ),
        ),
      ),
    );
  }
}
