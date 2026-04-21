import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../extension/game_phase.dart';

class DrinkSection extends StatelessWidget {
  final GamePhase phase;
  final VoidCallback onBackToStart;

  const DrinkSection({super.key, required this.phase, required this.onBackToStart});

  @override
  Widget build(BuildContext context) {
    final isReady = phase == GamePhase.drinkReady;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: switch (phase) {
        GamePhase.gameOver => _drinkStatusRow(
          color: AppColors.warning,
          title: 'Drink wird ermittelt …',
          subtitle: 'Verlierer bekommt seinen Spezial-Drink',
          loading: true,
        ),
        GamePhase.drinkSelecting => _drinkStatusRow(
          color: AppColors.primary,
          title: 'KI analysiert Loser-Foto …',
          subtitle: 'Drink wird ausgewählt',
          loading: true,
        ),
        GamePhase.drinkSending => _drinkStatusRow(
          color: AppColors.warning,
          title: 'Drink wird gemixt …',
          subtitle: 'Wird an Mixer geschickt',
          loading: true,
        ),
        GamePhase.drinkReady => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_bar_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dein Drink wird zubereitet!',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stell den Becher unter die Lichtschranke, dann startet das Pumpen.',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onBackToStart,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ZURÜCK ZUM START',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _drinkStatusRow({
    required Color color,
    required String title,
    required String subtitle,
    required bool loading,
  }) {
    return Row(
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyLarge.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.captionSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
