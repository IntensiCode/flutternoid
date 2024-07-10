import 'package:flame/components.dart';

import '../core/common.dart';
import 'game_phase.dart';

class Laser with Message {}

class Catcher with Message {}

class Expander with Message {}

class Disruptor with Message {}

class GameComplete with Message {}

class GameOver with Message {}

class SlowDown with Message {}

class MultiBall with Message {}

// alias for GamePhaseUpdate(enter_round)
class EnterRound with Message {}

class ExtraLife with Message {}

class LevelComplete with Message {}

class LevelReady with Message {}

class LoadLevel with Message {}

class PlayerReady with Message {}

class TriggerPlasmaBlasts with Message {}

class VausLost with Message {}

class GamePhaseUpdate with Message {
  final GamePhase phase;

  GamePhaseUpdate(this.phase);
}

class SpawnTeleport with Message {
  final Vector2 position;

  SpawnTeleport(this.position);
}

class TriggerPlasmaBlast with Message {
  final Vector2 center;

  TriggerPlasmaBlast(this.center);
}
