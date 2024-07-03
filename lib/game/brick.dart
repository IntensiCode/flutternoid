import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import 'brick_id.dart';

export 'brick_id.dart';

class SpawnExtraFromBrick with Message {
  final Brick brick;

  SpawnExtraFromBrick(this.brick);
}

class Brick {
  final BrickId id;
  final Vector2 topLeft;
  final Vector2 bottomRight;

  late final center = (topLeft + bottomRight) / 2;

  late final bool indestructible = id.strength == 0;

  Brick(this.id, this.topLeft, this.bottomRight);

  int _hits = 0;

  int get hits => _hits;

  bool get destroyed => !indestructible && _hits >= id.strength;

  bool spawned = false;

  void hit([bool full_force = false]) {
    hit_highlight += 0.1;
    if (indestructible) return;

    if (_hits < id.strength) {
      if (full_force) {
        _hits = id.strength;
      } else {
        _hits++;
      }
    }
    logInfo('hit $id: hits: $hits strength: ${id.strength}');
  }

  double hit_highlight = 0;
  double destroy_progress = 0.0;

  bool get gone => destroyed && destroy_progress >= 1.0;

  @override
  String toString() {
    final x = topLeft.x / 12;
    final y = topLeft.y / 6;
    return 'Brick(id: $id, x: $x, y: $y, hits: $hits, destroyed: $destroyed)';
  }
}
