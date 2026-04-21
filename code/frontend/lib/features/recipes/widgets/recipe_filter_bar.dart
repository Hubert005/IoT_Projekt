import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/recipe_models.dart';

class RecipeFilterBar extends StatelessWidget {
  final RecipeFilter selected;
  final ValueChanged<RecipeFilter> onSelected;

  const RecipeFilterBar({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          _FilterChipButton(
            label: 'All',
            active: selected == RecipeFilter.all,
            onTap: () => onSelected(RecipeFilter.all),
          ),
          _FilterChipButton(
            label: 'Available',
            active: selected == RecipeFilter.available,
            onTap: () => onSelected(RecipeFilter.available),
          ),
          _FilterChipButton(
            label: 'Favorites',
            active: selected == RecipeFilter.favorites,
            onTap: () => onSelected(RecipeFilter.favorites),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChipButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.92) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
