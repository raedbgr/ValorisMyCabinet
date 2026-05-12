import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/document_model.dart';

class RecentDocRow extends StatelessWidget {
  final DocumentModel doc;
  final bool isLast;

  const RecentDocRow({super.key, required this.doc, this.isLast = false});

  ({Color bg, Color fg, IconData icon}) get _style {
    switch (doc.category) {
      case DocumentCategory.facture:
        return (
          bg: AppColors.brandT,
          fg: AppColors.brand,
          icon: Icons.receipt_outlined,
        );
      case DocumentCategory.releve:
        return (
          bg: AppColors.greenT,
          fg: AppColors.green,
          icon: Icons.description_outlined,
        );
      case DocumentCategory.kbis:
        return (
          bg: AppColors.amberT,
          fg: AppColors.amber,
          icon: Icons.insert_drive_file_outlined,
        );
      default:
        return (
          bg: AppColors.bgSunk,
          fg: AppColors.text2,
          icon: Icons.description_outlined,
        );
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return "aujourd'hui";
    if (diff == 1) return 'hier';
    return '${d.day} ${_monthAbbr(d.month)}';
  }

  String _monthAbbr(int m) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      doc.categoryLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 2,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: AppColors.text3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}
