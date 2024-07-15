import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/functions.dart';
import '../core/random.dart';
import '../util/extensions.dart';
import 'enemy.dart';
import 'game_configuration.dart';

class EnemyCrystal extends Enemy {
  EnemyCrystal() : super(radius: 7, hit_points: 3);

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    final d = rng.nextBool() ? 1 : -1;
    body.linearVelocity.rotate(d * pi / 2);
    body.linearVelocity.rotate(rng.nextDoublePM(pi / 16));
  }

  @override
  onLoad() async {
    super.onLoad();
    animation = await sheetIWH('enemy_crystal.png', 16, 16);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state != EnemyState.active) return;
    if (position.y <= visual.game_pixels.y * 0.6) return;
    if (position.y >= visual.game_pixels.y * 0.8) return;

    final target = Vector2.copy(player.position);
    target.sub(position);
    body.linearVelocity.lerp(target, 0.5);
    body.linearVelocity.normalize();
    body.linearVelocity.scale(configuration.min_ball_speed);
  }
}
