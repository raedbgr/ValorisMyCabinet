import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum PillTone { green, amber, red, gray, brand }

class StatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.gray,
    this.dot = true,
  });

  Color get _fg {
    switch (tone) {
      case PillTone.green:
        return AppColors.green;
      case PillTone.amber:
        return AppColors.amber;
      case PillTone.red:
        return AppColors.red;
      case PillTone.gray:
        return AppColors.text2;
      case PillTone.brand:
        return AppColors.brand;
    }
  }

  Color get _bg {
    switch (tone) {
      case PillTone.green:
        return AppColors.greenT;
      case PillTone.amber:
        return AppColors.amberT;
      case PillTone.red:
        return AppColors.redT;
      case PillTone.gray:
        return AppColors.bgSunk;
      case PillTone.brand:
        return AppColors.brandT;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: _fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _fg,
              letterSpacing: 0.1,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
