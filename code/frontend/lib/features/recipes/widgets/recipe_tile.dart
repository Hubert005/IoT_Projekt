import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/recipe_models.dart';
import 'recipe_image.dart';
import 'status_badge.dart';

class RecipeTile extends StatelessWidget {
  final RecipeItem recipe;
  final VoidCallback? onTap;

  const RecipeTile({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = recipe.status == RecipeStatus.refillRequired;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 112,
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
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${recipe.totalVolumeMl} ml',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipe.mixSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.2,
                      ),
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
        ),
      ),
    );
  }
}
