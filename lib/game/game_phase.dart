enum GamePhase {
  confirm_exit,
  enter_round,
  game_on,
  game_over,
  game_paused,
  next_round,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}
