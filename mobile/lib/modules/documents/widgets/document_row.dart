import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/document_model.dart';

class DocumentRow extends StatelessWidget {
  final DocumentModel doc;
  final bool isLast;
  final VoidCallback? onTap;

  const DocumentRow({
    super.key,
    required this.doc,
    this.isLast = false,
    this.onTap,
  });

  ({Color bg, Color fg, IconData icon}) get _style {
    switch (doc.category) {
      case DocumentCategory.facture:
        return (bg: AppColors.brandT, fg: AppColors.brand, icon: Icons.receipt_outlined);
      case DocumentCategory.releve:
        return (bg: AppColors.greenT, fg: AppColors.green, icon: Icons.description_outlined);
      case DocumentCategory.kbis:
        return (bg: AppColors.amberT, fg: AppColors.amber, icon: Icons.insert_drive_file_outlined);
      case DocumentCategory.justificatif:
        return (bg: AppColors.bgSunk, fg: AppColors.text2, icon: Icons.image_outlined);
      default:
        return (bg: AppColors.bgSunk, fg: AppColors.text2, icon: Icons.description_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 46,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(s.icon, size: 20, color: s.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: s.bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          doc.categoryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: s.fg,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(doc.uploadedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (doc.status == DocumentStatus.processing)
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amber,
                      backgroundColor: AppColors.amberT,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Classement…',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.check, size: 16, color: AppColors.green),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return "aujourd'hui";
    if (diff == 1) return 'hier';
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
