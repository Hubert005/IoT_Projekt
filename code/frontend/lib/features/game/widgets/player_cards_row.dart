import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/round_result.dart';
import 'player_card.dart';

class PlayerCardsRow extends StatelessWidget {
  final String player1ImagePath;
  final String player2ImagePath;
  final int? seriesWinner;
  final bool gameOver;
  final RoundResult? lastRound;
  final bool waiting;

  const PlayerCardsRow({
    super.key,
    required this.player1ImagePath,
    required this.player2ImagePath,
    required this.seriesWinner,
    required this.gameOver,
    required this.lastRound,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PlayerCard(
              imagePath: player1ImagePath,
              label: l10n.playerLabel(1),
              isWinner: gameOver && seriesWinner == 1,
              isLoser: gameOver && seriesWinner == 2,
              gameOver: gameOver,
              gesture: lastRound?.p1,
              waiting: waiting,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PlayerCard(
              imagePath: player2ImagePath,
              label: l10n.playerLabel(2),
              isWinner: gameOver && seriesWinner == 2,
              isLoser: gameOver && seriesWinner == 1,
              gameOver: gameOver,
              gesture: lastRound?.p2,
              waiting: waiting,
            ),
          ),
        ],
      ),
    );
  }
}
