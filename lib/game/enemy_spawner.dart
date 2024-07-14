import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutternoid/core/messaging.dart';
import 'package:flutternoid/game/doh.dart';
import 'package:flutternoid/game/doh_disc.dart';
import 'package:flutternoid/game/soundboard.dart';
import 'package:flutternoid/util/delayed.dart';

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
  String get id {
    if (this is DohDisc) return 'disc';
    if (this is EnemyCrystal) return 'crystal';
    if (this is EnemyGlobolus) return 'globolus';
    throw 'unknown enemy type: $this';
  }
}

class EnemySpawner extends PositionComponent with AutoDispose, GameContext, HasPaint {
  late final EnemyDoor left_door;
  late final EnemyDoor right_door;

  final pending_enemies = <String>[];
  int destroyed = 0;

  double random_delay = 0.0;

  Iterable<Enemy> get active_enemies => top_level_children<Enemy>();

  bool get all_enemies_destroyed => destroyed == level.enemies.length;

  // Component

  @override
  onLoad() async {
    priority = 5;
    position.setFrom(visual.background_offset);
    await add(left_door = EnemyDoor()..position.setValues(22, 0));
    await add(right_door = EnemyDoor()..position.setValues(151, 0));
    onMessage<EnemyDestroyed>((_) {
      destroyed++;
      logInfo('on EnemyDestroyed: all enemies destroyed? $all_enemies_destroyed');
    });
    onMessage<GameComplete>((_) {
      final active = top_level_children<Enemy>();
      for (final it in active) {
        logInfo('teleport ${it.id}');
        sendMessage(SpawnTeleport(it.position));
        it.removeFromParent();
      }
      if (active.isNotEmpty) soundboard.play(Sound.teleport);
    });
    onMessage<LevelComplete>((_) {
      logInfo('on LevelComplete: all enemies destroyed? $all_enemies_destroyed');
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
      destroyed = 0;
    });
    onMessage<VausLost>((_) {
      final active = top_level_children<Enemy>();
      for (final it in active) {
        logInfo('teleport ${it.id}');
        sendMessage(SpawnTeleport(it.position));
        it.removeFromParent();
        if (it is DohDisc) continue;
        pending_enemies.insert(0, it.id);
      }
      if (active.isNotEmpty) soundboard.play(Sound.teleport);
      logInfo(pending_enemies);
    });
    onMessage<LevelDataAvailable>((_) {
      pending_enemies.clear();
      pending_enemies.addAll(level.enemies);
      destroyed = 0;

      final doh = level.doh;
      if (doh != null) {
        add(Delayed(0.5, () => spawn_top_level(Doh(doh)..fadeInDeep())));
      }
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
