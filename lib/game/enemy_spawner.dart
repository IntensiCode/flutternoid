import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutternoid/core/messaging.dart';
import 'package:flutternoid/game/soundboard.dart';

import '../core/random.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'enemy.dart';
import 'enemy_crystal.dart';
import 'enemy_door.dart';
import 'enemy_globolus.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'player.dart';

extension on Enemy {
  String get id => runtimeType.toString().replaceFirst('Enemy', '').toLowerCase();
}

class EnemySpawner extends PositionComponent with AutoDispose, HasPaint {
  late final EnemyDoor left_door;
  late final EnemyDoor right_door;

  final pending_enemies = <String>[];

  double random_delay = 0.0;

  Iterable<Enemy> get active_enemies => top_level_children<Enemy>();

  // Component

  @override
  onLoad() async {
    priority = 5;
    position.setFrom(visual.background_offset);
    await add(left_door = EnemyDoor()..position.setValues(22, 0));
    await add(right_door = EnemyDoor()..position.setValues(151, 0));
    onMessage<LevelComplete>((_) {
      final active = top_level_children<Enemy>();
      for (final it in active) {
        logInfo('teleport ${it.id}');
        sendMessage(SpawnTeleport(it.position));
        it.removeFromParent();
      }
      if (active.isNotEmpty) soundboard.play(Sound.teleport);
      pending_enemies.clear();
    });
    onMessage<EnterRound>((_) {
      pending_enemies.clear();
      pending_enemies.addAll(level.enemies);
    });
    onMessage<VausLost>((_) {
      final active = top_level_children<Enemy>();
      for (final it in active) {
        logInfo('teleport ${it.id}');
        sendMessage(SpawnTeleport(it.position));
        it.removeFromParent();
        pending_enemies.insert(0, it.id);
      }
      if (active.isNotEmpty) soundboard.play(Sound.teleport);
      logInfo(pending_enemies);
    });
  }

  @override
  void update(double dt) {
    if (phase != GamePhase.game_on) return;
    super.update(dt);
    if (player.state != PlayerState.playing) return;
    if (pending_enemies.isEmpty) return;
    if (active_enemies.length >= level.max_concurrent_enemies) return;

    if (random_delay > 0) {
      random_delay -= dt;
      return;
    }

    final doors = [left_door, right_door].where((it) => !it.is_blocked).toList();
    if (doors.isEmpty) return;

    final door = doors.random(rng);

    final id = pending_enemies.removeAt(0);
    final enemy = switch (id) {
      'globolus' => EnemyGlobolus(),
      'crystal' => EnemyCrystal(),
      _ => throw 'unknown enemy: $id',
    };
    door.release(enemy);

    random_delay = 1 + rng.nextDoubleLimit(5);
  }
}
