import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/round_result.dart';

class SeriesStatsCard extends StatelessWidget {
  final int seriesLength;
  final List<RoundResult> rounds;
  final int player1Wins;
  final int player2Wins;
  final bool postGame;
  final int? seriesWinner;

  const SeriesStatsCard({
    super.key,
    required this.seriesLength,
    required this.rounds,
    required this.player1Wins,
    required this.player2Wins,
    required this.postGame,
    required this.seriesWinner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.seriesStats(seriesLength),
                style: AppTextStyles.captionSmall.copyWith(
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.roundXofY(rounds.length, seriesLength),
                style: AppTextStyles.captionSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.player1Label,
                      style: AppTextStyles.captionSmall.copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$player1Wins',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: postGame && seriesWinner == 1
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(seriesLength, (i) {
                  final r = i < rounds.length ? rounds[i] : null;
                  final Color color;
                  if (r == null) {
                    color = AppColors.progressTrack;
                  } else if (r.winner == 1) {
                    color = AppColors.primary;
                  } else if (r.winner == 2) {
                    color = AppColors.error;
                  } else {
                    color = AppColors.warning;
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _RoundDot(label: 'R${i + 1}', color: color, active: r != null),
                  );
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.player2Label,
                      style: AppTextStyles.captionSmall.copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$player2Wins',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: postGame && seriesWinner == 2
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundDot extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;

  const _RoundDot({required this.label, required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.18) : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: active ? color : AppColors.border, width: 1.5),
          ),
          child: active
              ? Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTextStyles.captionSmall.copyWith(
            color: active ? color : AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
