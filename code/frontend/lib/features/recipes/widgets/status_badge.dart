import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/recipe_models.dart';

class StatusBadge extends StatelessWidget {
  final RecipeStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      RecipeStatus.ready => ('READY', const Color(0xFF0C3A2A), AppColors.success),
      RecipeStatus.lowStock => ('LOW STOCK', const Color(0xFF3E3213), AppColors.warning),
      RecipeStatus.refillRequired => ('REFILL', const Color(0xFF411C26), AppColors.error),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: AppTextStyles.captionSmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
