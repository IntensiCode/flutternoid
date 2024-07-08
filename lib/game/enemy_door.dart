import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../core/functions.dart';
import 'enemy.dart';
import 'game_context.dart';

enum DoorState {
  idle,
  opening,
  spawning,
  closing,
}

class EnemyDoor extends PositionComponent with HasPaint {
  late final SpriteSheet door;

  DoorState state = DoorState.idle;

  bool get is_blocked => state != DoorState.idle;

  Enemy? spawn_target;
  double open_progress = 0.0;

  release(Enemy enemy) {
    logInfo('releasing $enemy');
    if (is_blocked) throw 'no no';
    spawn_target = enemy;
    state = DoorState.opening;
  }

  // Component

  @override
  onLoad() async => door = await sheetIWH('game_door.png', 27, 8);

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case DoorState.idle:
        break;
      case DoorState.opening:
        open_progress += dt;
        if (open_progress >= 1.0) {
          open_progress = 1.0;
          state = DoorState.spawning;
          final spawn_pos = Vector2.copy(position);
          spawn_pos.x += 3;
          spawn_pos.y -= 20;
          spawn_target?.spawn_at(spawn_pos);
          spawn_top_level(spawn_target!);
        }
      case DoorState.spawning:
        if (spawn_target?.state != EnemyState.spawned) {
          state = DoorState.closing;
        }
        break;
      case DoorState.closing:
        open_progress -= dt;
        if (open_progress <= 0.0) {
          open_progress = 0.0;
          state = DoorState.idle;
        }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (state) {
      case DoorState.idle:
        door.getSpriteById(0).render(canvas, overridePaint: paint);
      case DoorState.opening:
        final frames = door.columns * door.rows;
        final frame = ((open_progress * (frames - 1)).toInt()).clamp(0, frames - 1).toInt();
        door.getSpriteById(frame).render(canvas, overridePaint: paint);
      case DoorState.spawning:
        break;
      case DoorState.closing:
        final frames = door.columns * door.rows;
        final frame = ((open_progress * (frames - 1)).toInt()).clamp(0, frames - 1).toInt();
        door.getSpriteById(frame).render(canvas, overridePaint: paint);
    }
  }
}
