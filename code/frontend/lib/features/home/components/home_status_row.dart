import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import 'status_card.dart';

class HomeStatusRow extends StatelessWidget {
  final String wifiInfo;
  final bool connected;
  final VoidCallback? onTap;

  const HomeStatusRow({
    super.key,
    required this.wifiInfo,
    this.connected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox(width: 36),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: StatusCard(
              title: l10n.wifiStatus,
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
