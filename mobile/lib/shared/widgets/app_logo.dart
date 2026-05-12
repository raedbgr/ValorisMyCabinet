import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    final dotSize = size * 0.24;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withAlpha(100),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.46, size * 0.46),
                painter: _DocLinesPainter(),
              ),
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bg,
                  width: size * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rr = Radius.circular(size.height * 0.05);

    paint.color = Colors.white.withAlpha(242);
    canvas.drawRRect(
        RRect.fromLTRBR(0, size.height * 0.17, size.width, size.height * 0.27, rr), paint);

    paint.color = Colors.white.withAlpha(153);
    canvas.drawRRect(
        RRect.fromLTRBR(0, size.height * 0.45, size.width, size.height * 0.55, rr), paint);

    paint.color = Colors.white.withAlpha(89);
    canvas.drawRRect(
        RRect.fromLTRBR(0, size.height * 0.73, size.width * 0.61, size.height * 0.83, rr),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
