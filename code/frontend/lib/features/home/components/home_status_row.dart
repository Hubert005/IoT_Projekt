import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'status_card.dart';

class HomeStatusRow extends StatelessWidget {
  final String wifiInfo;
  final bool connected;
  final VoidCallback? onTap;

  const HomeStatusRow({
    super.key,
    this.wifiInfo = 'Arduino IP automatisch abgefragt',
    this.connected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 36),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: StatusCard(
              title: 'WLAN STATUS',
              value: wifiInfo,
              valueColor: connected ? AppColors.success : AppColors.textPrimary,
              showDot: connected,
              trailingIcon: connected ? Icons.wifi : Icons.wifi_off,
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}
