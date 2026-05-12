import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/deadline_model.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../navigation/main_navigation_controller.dart';

class HeroDeadlineCard extends StatelessWidget {
  final DeadlineModel deadline;

  const HeroDeadlineCard({super.key, required this.deadline});

  int get _daysLeft => deadline.dueDate.difference(DateTime.now()).inDays;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(label: deadline.statusLabel, tone: _pillTone),
                  const SizedBox(height: 6),
                  Text(
                    'Prochaine échéance',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_daysLeft',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'jours',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.text2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            deadline.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            deadline.period,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (deadline.missingDocs > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.redT,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBD5D5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                  const SizedBox(width: 10),
                  Text(
                    '${deadline.missingDocs} document${deadline.missingDocs > 1 ? 's' : ''} manquant${deadline.missingDocs > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Get.find<MainNavigationController>().goToCalendar(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Voir le détail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: AppColors.brand),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
