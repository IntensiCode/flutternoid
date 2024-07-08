enum GamePhase {
  round_intro,
  next_round,
  game_on,
  game_paused,
  game_over,
  confirm_exit,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}
