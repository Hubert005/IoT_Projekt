import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'status_card.dart';

class HomeStatusRow extends StatelessWidget {
  final bool bleConnected;
  final String? bleDeviceName;
  final VoidCallback? onBleTap;

  const HomeStatusRow({
    super.key,
    this.bleConnected = false,
    this.bleDeviceName,
    this.onBleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 36),
        Expanded(
          child: GestureDetector(
            onTap: onBleTap,
            child: StatusCard(
              title: 'BLE STATUS',
              value: bleConnected
                  ? (bleDeviceName ?? 'Verbunden')
                  : 'Tippen zum Verbinden',
              valueColor: bleConnected ? AppColors.success : AppColors.textPrimary,
              showDot: bleConnected,
              trailingIcon: bleConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}
