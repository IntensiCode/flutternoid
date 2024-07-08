import 'package:flutternoid/game/extra_id.dart';

enum BrickId {
  // top
  blue1('B1', strength: 1, score_per_hit: 1, extras: {ExtraId.disruptor}),
  green1('G1', strength: 1, score_per_hit: 1, extras: {ExtraId.catcher}),
  orange1('O1', strength: 1, score_per_hit: 1, extras: {ExtraId.slow_down}),
  gray1('G1', strength: 1, score_per_hit: 1, extras: {}),
  red1('R1', strength: 1, score_per_hit: 1, extras: {ExtraId.multi_ball}),
  // middle
  blue2('B2', strength: 1, score_per_hit: 2, extras: {ExtraId.expander}),
  green2('G2', strength: 1, score_per_hit: 2, extras: {ExtraId.catcher}),
  orange2('O2', strength: 1, score_per_hit: 2, extras: {ExtraId.slow_down}),
  gray2('G2', strength: 1, score_per_hit: 2, extras: {}),
  red2('R2', strength: 1, score_per_hit: 2, extras: {ExtraId.laser}),
  // bottom
  double('DD', strength: 6, score_per_hit: 6, extras: {ExtraId.extra_life}),
  green3('G3', strength: 3, score_per_hit: 3, extras: {ExtraId.catcher}),
  orange3('O3', strength: 3, score_per_hit: 3, extras: {ExtraId.slow_down}),
  gray3('G3', strength: 3, score_per_hit: 3, extras: {}),
  massive('MM', strength: 0, score_per_hit: 0, extras: {}),
  ;

  final String id;
  final int strength;
  final int score_per_hit;
  final Set<ExtraId> extras;

  const BrickId(this.id, {required this.strength, required this.score_per_hit, required this.extras});

  static BrickId from(String name) => BrickId.values.firstWhere((e) => e.name == name);

  static BrickId from_id(String id) => BrickId.values.firstWhere((e) => e.id == id);
}
