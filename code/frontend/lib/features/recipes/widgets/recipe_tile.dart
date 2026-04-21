import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/recipe_models.dart';
import 'recipe_image.dart';
import 'status_badge.dart';

class RecipeTile extends StatelessWidget {
  final RecipeItem recipe;

  const RecipeTile({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final locked = recipe.status == RecipeStatus.refillRequired;

    return Container(
      height: 82,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 68, height: 68, child: RecipeImage(url: recipe.imageUrl)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: AppTextStyles.bodyLarge.copyWith(fontSize: 21, height: 1.05),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: recipe.status, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recipe.subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 3),
                Text(
                  recipe.volumeAndTime,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
            color: locked ? AppColors.textTertiary : AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
