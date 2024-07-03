import 'package:flutternoid/game/extra_id.dart';

enum BrickId {
  // top
  blue1('B1', strength: 1, score_per_hit: 1, extras: basic),
  green1('G1', strength: 1, score_per_hit: 1, extras: basic),
  orange1('O1', strength: 1, score_per_hit: 1, extras: basic),
  gray1('G1', strength: 1, score_per_hit: 1, extras: basic),
  red1('R1', strength: 1, score_per_hit: 1, extras: basic),
  // middle
  blue2('B2', strength: 1, score_per_hit: 2, extras: most),
  green2('G2', strength: 1, score_per_hit: 2, extras: most),
  orange2('O2', strength: 1, score_per_hit: 2, extras: most),
  gray2('G2', strength: 1, score_per_hit: 2, extras: most),
  red2('R2', strength: 1, score_per_hit: 2, extras: most),
  // bottom
  double('DD', strength: 6, score_per_hit: 6, extras: all),
  green3('G3', strength: 3, score_per_hit: 3, extras: all),
  orange3('O3', strength: 3, score_per_hit: 3, extras: all),
  gray3('G3', strength: 3, score_per_hit: 3, extras: all),
  massive('MM', strength: 0, score_per_hit: 0, extras: {}),
  ;

  final String id;
  final int strength;
  final int score_per_hit;
  final Set<ExtraId> extras;

  static const basic = {
    ExtraId.catcher,
    ExtraId.expander,
    ExtraId.slow_down,
  };

  static const most = {
    ExtraId.laser,
    ExtraId.catcher,
    ExtraId.expander,
    ExtraId.slow_down,
    ExtraId.multi_ball,
  };

  static const all = {
    ExtraId.laser,
    ExtraId.catcher,
    ExtraId.expander,
    ExtraId.disruptor,
    ExtraId.slow_down,
    ExtraId.multi_ball,
    ExtraId.extra_life,
  };

  const BrickId(this.id, {required this.strength, required this.score_per_hit, required this.extras});

  static BrickId from(String name) => BrickId.values.firstWhere((e) => e.name == name);

  static BrickId from_id(String id) => BrickId.values.firstWhere((e) => e.id == id);
}
