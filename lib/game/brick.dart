import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/common.dart';
import 'brick_id.dart';
import 'extra_id.dart';

export 'brick_id.dart';

class SpawnExtraFromBrick with Message {
  final Brick brick;

  SpawnExtraFromBrick(this.brick);
}

class Brick extends BodyComponent {
  final BrickId id;
  final Vector2 topLeft;
  final Vector2 bottomRight;

  Set<ExtraId>? extra_id;

  late final spawn_center = (topLeft + bottomRight) / 2;

  late final bool indestructible = id.strength == 0;

  Brick(this.id, this.topLeft, this.bottomRight) {
    renderBody = false;
    paint.style = PaintingStyle.stroke;
  }

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
  Body createBody() {
    final width = bottomRight.x - topLeft.x;
    final height = bottomRight.y - topLeft.y;

    final shape = PolygonShape()..setAsBox(width / 2, height / 2, Vector2(width / 2, height / 2), 0);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.0,
      restitution: 0.0,
      density: 1000,
    );
    final bodyDef = BodyDef(
      gravityOverride: Vector2.zero(),
      userData: this, // To be able to determine object in collision
      position: topLeft,
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  String toString() {
    final x = topLeft.x / 12;
    final y = topLeft.y / 6;
    return 'Brick(id: $id, x: $x, y: $y, hits: $hits, destroyed: $destroyed, extra_id: $extra_id)';
  }
}
