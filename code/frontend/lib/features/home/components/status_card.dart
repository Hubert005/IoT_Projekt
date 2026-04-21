import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final IconData? trailingIcon;
  final bool showDot;

  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
    this.trailingIcon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.captionSmall
                      .copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      value,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: valueColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: valueColor, size: 22),
        ],
      ),
    );
  }
}
