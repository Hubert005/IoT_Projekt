enum GamePhase { waitingRound, showingRound, gameOver, drinkSelecting, drinkSending, drinkReady }

extension GamePhaseExt on GamePhase {
  bool get isPostGame => index >= GamePhase.gameOver.index;
}
