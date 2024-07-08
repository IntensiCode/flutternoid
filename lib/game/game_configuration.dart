final configuration = GameConfiguration.instance;

class GameConfiguration {
  static final instance = GameConfiguration._();

  GameConfiguration._();

  double mode_time = 30;
  double expand_time = 60;
  double slow_down_time = 60;
  double disruptor_time = 10;

  double force_hold_timeout = 1.0;
  double plasma_cool_down = 3.0;
  double plasma_disruptor = 1.0;

  final max_ball_speed = 150.0;
  final opt_ball_speed = 100.0;
  final min_ball_speed = 25.0;
  final min_ball_x_speed_after_brick_hit = 10;
}
