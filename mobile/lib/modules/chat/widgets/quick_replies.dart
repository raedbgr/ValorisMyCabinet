import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class QuickReplies extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onSelect;

  const QuickReplies({
    super.key,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options
          .map(
            (o) => GestureDetector(
              onTap: () => onSelect(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.brand),
                ),
                child: Text(
                  o,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
