import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'status_card.dart';

class HomeStatusRow extends StatelessWidget {
  const HomeStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatusCard(
            title: 'WIFI NETWORK',
            value: 'Connected',
            valueColor: AppColors.success,
            trailingIcon: Icons.wifi_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatusCard(
            title: 'MACHINE STATUS',
            value: 'Online',
            valueColor: AppColors.textPrimary,
            showDot: true,
          ),
        ),
      ],
    );
  }
}
