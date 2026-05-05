import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RecipeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const RecipeSearchField({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: l10n.searchHint,
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary.withValues(alpha: 0.75)),
          contentPadding: const EdgeInsets.only(top: 12),
        ),
      ),
    );
  }
}
