import 'package:flutter/material.dart';
import 'package:iot_drink_mixer/core/theme/app_colors.dart';
import '../../models/drink.dart';
import '../../models/round_result.dart';
import '../../services/backend_service.dart';
import '../../services/ble_service.dart';
import '../../services/drink_service.dart';
import '../../services/mixer_service.dart';
import 'extension/game_phase.dart';
import 'widgets/ble_debug_panel.dart';
import 'widgets/drink_section.dart';
import 'widgets/game_result_header.dart';
import 'widgets/player_cards_row.dart';
import 'widgets/series_stats_card.dart';

class GameScreen extends StatefulWidget {
  final String player1ImagePath;
  final String player2ImagePath;
  final BackendService backend;
  final DrinkService drinkService;
  final MixerService mixerService;

  const GameScreen({
    super.key,
    required this.player1ImagePath,
    required this.player2ImagePath,
    required this.backend,
    required this.drinkService,
    required this.mixerService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _seriesLength = 3;

  final List<RoundResult> _rounds = [];
  GamePhase _phase = GamePhase.waitingRound;
  int _currentRound = 1;
  Drink? _drink;

  int get _p1Wins => _rounds.where((r) => r.winner == 1).length;
  int get _p2Wins => _rounds.where((r) => r.winner == 2).length;

  int? get _seriesWinner {
    if (_p1Wins >= 2) return 1;
    if (_p2Wins >= 2) return 2;
    if (_rounds.length >= _seriesLength) {
      if (_p1Wins > _p2Wins) return 1;
      if (_p2Wins > _p1Wins) return 2;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (BleService.instance.isConnected) {
      await BleService.instance.send('start');
      await BleService.instance.waitForMessage('start_ok');
    }
    if (mounted) _playRound();
  }


  Future<void> _playRound() async {
    if (!mounted) return;
    setState(() => _phase = GamePhase.waitingRound);

    final result = await widget.backend.getRoundResult(_currentRound);
    if (!mounted) return;

    setState(() {
      _rounds.add(result);
      _phase = GamePhase.showingRound;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_seriesWinner != null) {
      setState(() => _phase = GamePhase.gameOver);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _selectDrink();
    } else {
      setState(() => _currentRound++);
      _playRound();
    }
  }

  Future<void> _selectDrink() async {
    if (!mounted) return;
    setState(() => _phase = GamePhase.drinkSelecting);

    final loser = _seriesWinner == 1 ? 2 : 1;
    final loserPath = loser == 1 ? widget.player1ImagePath : widget.player2ImagePath;

    final drink = await widget.drinkService.selectDrink(
      loserPlayer: loser,
      loserImagePath: loserPath,
    );
    if (!mounted) return;

    setState(() {
      _drink = drink;
      _phase = GamePhase.drinkSending;
    });

    await widget.mixerService.orderDrink(drink);
    if (!mounted) return;

    setState(() => _phase = GamePhase.drinkReady);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: BleService.instance.isConnected
          ? FloatingActionButton.small(
              onPressed: _openDebugPanel,
              backgroundColor: Colors.white12,
              child: const Icon(Icons.bug_report, color: Colors.white54),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            GameResultHeader(
              phase: _phase,
              currentRound: _currentRound,
              roundsLength: _rounds.length,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    PlayerCardsRow(
                      player1ImagePath: widget.player1ImagePath,
                      player2ImagePath: widget.player2ImagePath,
                      seriesWinner: _seriesWinner,
                      gameOver: _phase.isPostGame,
                      lastRound: _rounds.isNotEmpty ? _rounds.last : null,
                      waiting: _phase == GamePhase.waitingRound,
                    ),
                    const SizedBox(height: 16),
                    SeriesStatsCard(
                      seriesLength: _seriesLength,
                      rounds: _rounds,
                      player1Wins: _p1Wins,
                      player2Wins: _p2Wins,
                      postGame: _phase.isPostGame,
                      seriesWinner: _seriesWinner,
                    ),
                    if (_phase.isPostGame) ...[
                      const SizedBox(height: 16),
                      DrinkSection(
                        phase: _phase,
                        onBackToStart: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDebugPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const BleDebugPanel(),
    );
  }
}
