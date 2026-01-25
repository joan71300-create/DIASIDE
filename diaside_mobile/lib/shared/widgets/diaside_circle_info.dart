import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DiasideCircleInfo extends StatelessWidget {
  final String title;
  final String value;
  final double size;
  final Color color;

  const DiasideCircleInfo({
    super.key,
    required this.title,
    required this.value,
    this.size = 120,
    this.color = AppColors.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 8),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.2 * 255).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: size * 0.1,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size * 0.2,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
