import 'package:flame/components.dart';

import '../core/common.dart';
import 'game_phase.dart';

class Catcher with Message {}

class Disruptor with Message {}

class DohVanishing with Message {}

class EnemyDestroyed with Message {}

class EnterRound with Message {}

class Expander with Message {}

class ExtraLife with Message {}

class GameComplete with Message {}

class GameOver with Message {}

class Laser with Message {}

class LevelComplete with Message {}

class LevelDataAvailable with Message {}

class LevelReady with Message {}

class LoadLevel with Message {}

class MultiBall with Message {}

class PlayerExploding with Message {}

class PlayerReady with Message {}

class SlowDown with Message {}

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
