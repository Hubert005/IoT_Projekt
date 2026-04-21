import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PhotoCaptureHeader extends StatelessWidget {
  final VoidCallback onBack;

  const PhotoCaptureHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ),
        const Spacer(),
        Text('Fotos aufnehmen', style: AppTextStyles.headingSmall),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }
}
