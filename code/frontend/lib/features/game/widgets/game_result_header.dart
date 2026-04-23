import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../extension/game_phase.dart';

class GameResultHeader extends StatelessWidget {
  final GamePhase phase;
  final int currentRound;
  final int roundsLength;

  const GameResultHeader({
    super.key,
    required this.phase,
    required this.currentRound,
    required this.roundsLength,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (text, color, loading) = switch (phase) {
      GamePhase.waitingRound => (l10n.waitingForRound(currentRound), AppColors.warning, true),
      GamePhase.showingRound => (l10n.resultRound(roundsLength), AppColors.info, false),
      GamePhase.gameOver => (l10n.gameResultTitle, AppColors.primary, false),
      GamePhase.drinkSelecting => (l10n.drinkSelectingStatus, AppColors.warning, true),
      GamePhase.drinkSending => (l10n.drinkSendingStatus, AppColors.warning, true),
      GamePhase.drinkReady => (l10n.drinkReadyStatus, AppColors.success, false),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Column(
        children: [
          Text(l10n.gameResultHeading, style: AppTextStyles.headingLarge),
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
