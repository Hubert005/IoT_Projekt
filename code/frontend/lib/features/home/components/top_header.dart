import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class TopHeader extends StatelessWidget {
  final String title;
  const TopHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTextStyles.headingSmall),
        ),
      ],
    );
  }
}
