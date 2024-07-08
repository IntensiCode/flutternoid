enum GamePhase {
  doh_intro,
  game_on,
  game_paused,
  game_over,
  confirm_exit,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}
