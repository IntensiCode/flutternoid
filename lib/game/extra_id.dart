import '../core/common.dart';

class Laser with Message {}
class Catcher with Message {}
class Expander with Message {}
class Disruptor with Message {}
class SlowDown with Message {}
class MultiBall with Message {}
class ExtraLife with Message {}

// order matches row in sprite sheet
enum ExtraId {
  laser(0.05),
  catcher(0.1),
  expander(0.3),
  disruptor(0.1),
  slow_down(0.3),
  multi_ball(0.1),
  extra_life(0.01),
  ;

  final double probability;

  const ExtraId(this.probability);

  static ExtraId from(String name) => ExtraId.values.firstWhere((e) => e.name == name);
}
