import 'package:flame/components.dart';

import '../core/common.dart';
import 'game_phase.dart';

class Laser with Message {}

class Catcher with Message {}

class Expander with Message {}

class Disruptor with Message {}

class SlowDown with Message {}

class MultiBall with Message {}

class ExtraLife with Message {}

class LevelComplete with Message {}

class GamePhaseUpdate with Message {
  final GamePhase phase;

  GamePhaseUpdate(this.phase);
}

class PlayerReady with Message {}

class TriggerPlasmaBlast with Message {
  final Vector2 center;

  TriggerPlasmaBlast(this.center);
}

class TriggerPlasmaBlasts with Message {}
