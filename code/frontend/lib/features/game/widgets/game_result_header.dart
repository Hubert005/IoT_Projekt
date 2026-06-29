import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../extension/game_phase.dart';

class GameResultHeader extends StatelessWidget {
  final GamePhase phase;
  final int currentRound;

  const GameResultHeader({
    super.key,
    required this.phase,
    required this.currentRound,
  });

  @override
  Widget build(BuildContext context) {
    final (text, color, loading) = switch (phase) {
      GamePhase.waitingRound => ('WARTE AUF RUNDE $currentRound …', AppColors.warning, true),
      GamePhase.showingRound => ('ERGEBNIS RUNDE $currentRound', AppColors.info, false),
      GamePhase.gameOver => ('SPIELERGEBNIS', AppColors.primary, false),
      GamePhase.drinkSelecting => ('DRINK WIRD ERMITTELT …', AppColors.warning, true),
      GamePhase.drinkSending => ('WIRD AN MIXER GESCHICKT …', AppColors.warning, true),
      GamePhase.drinkReady => ('DRINK BESTÄTIGT', AppColors.success, false),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Column(
        children: [
          Text('Game Result', style: AppTextStyles.headingLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 7,
                    height: 7,
                    child: CircularProgressIndicator(color: color, strokeWidth: 1.5),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: color,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
