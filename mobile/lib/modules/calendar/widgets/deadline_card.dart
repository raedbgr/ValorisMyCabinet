import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/deadline_model.dart';
import '../../../shared/widgets/status_pill.dart';

class DeadlineCard extends StatelessWidget {
  final DeadlineModel deadline;
  final VoidCallback? onTap;

  const DeadlineCard({super.key, required this.deadline, this.onTap});

  Color get _borderColor {
    switch (deadline.status) {
      case DeadlineStatus.urgent:
        return AppColors.amber;
      case DeadlineStatus.late:
        return AppColors.red;
      case DeadlineStatus.complete:
        return AppColors.green;
      case DeadlineStatus.upcoming:
        return AppColors.text3;
    }
  }

  PillTone get _pillTone {
    switch (deadline.status) {
      case DeadlineStatus.urgent:
        return PillTone.amber;
      case DeadlineStatus.late:
        return PillTone.red;
      case DeadlineStatus.complete:
        return PillTone.green;
      case DeadlineStatus.upcoming:
        return PillTone.gray;
    }
  }

  Color get _codeColor {
    switch (deadline.status) {
      case DeadlineStatus.urgent:
        return AppColors.amber;
      case DeadlineStatus.late:
        return AppColors.red;
      case DeadlineStatus.complete:
        return AppColors.green;
      case DeadlineStatus.upcoming:
        return AppColors.brand;
    }
  }

  Color get _codeBg {
    switch (deadline.status) {
      case DeadlineStatus.urgent:
        return AppColors.amberT;
      case DeadlineStatus.late:
        return AppColors.redT;
      case DeadlineStatus.complete:
        return AppColors.greenT;
      case DeadlineStatus.upcoming:
        return AppColors.brandT;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isComplete = deadline.status == DeadlineStatus.complete;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isComplete ? 0.78 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // left color bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // type badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _codeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          deadline.code,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _codeColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  deadline.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                    letterSpacing: -0.2,
                                    decoration: isComplete
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.text3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: deadline.statusLabel,
                                tone: _pillTone,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            deadline.period,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.text2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(top: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_outlined,
                                  size: 13,
                                  color: AppColors.text3,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${_formatDue(deadline.dueDate)} · ${deadline.relativeDate(now)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _relativeColor,
                                    ),
                                  ),
                                ),
                                if (deadline.missingDocs >= 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: deadline.missingDocs > 0
                                          ? _missingColor
                                          : AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      deadline.missingDocs > 0
                                          ? '${deadline.missingDocs} doc${deadline.missingDocs > 1 ? 's' : ''} manquant${deadline.missingDocs > 1 ? 's' : ''}'
                                          : 'Complet',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: deadline.missingDocs > 0
                                            ? _missingColor
                                            : AppColors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _relativeColor {
    switch (deadline.status) {
      case DeadlineStatus.urgent:
        return AppColors.amber;
      case DeadlineStatus.late:
        return AppColors.red;
      default:
        return AppColors.text2;
    }
  }

  Color get _missingColor {
    if (deadline.status == DeadlineStatus.upcoming && deadline.missingDocs == 1) {
      return AppColors.amber;
    }
    return AppColors.red;
  }

  String _formatDue(DateTime d) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
