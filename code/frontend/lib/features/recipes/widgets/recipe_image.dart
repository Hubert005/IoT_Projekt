import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RecipeImage extends StatelessWidget {
  final String url;

  const RecipeImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: AppColors.surfaceSecondary,
          child: Icon(
            Icons.local_bar_rounded,
            color: AppColors.primary.withValues(alpha: 0.7),
            size: 26,
          ),
        );
      },
    );
  }
}
