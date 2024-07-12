import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutternoid/core/random.dart';
import 'package:flutternoid/game/ball.dart';
import 'package:flutternoid/game/doh.dart';
import 'package:flutternoid/game/game_messages.dart';
import 'package:flutternoid/util/on_message.dart';

import '../core/functions.dart';
import 'enemy.dart';
import 'visual_configuration.dart';
import 'wall.dart';

class DohDisc extends Enemy {
  DohDisc(Vector2 start, Vector2 velocity) : super(radius: 5, hit_points: 1) {
    forced_position.setFrom(start);
    forced_velocity.setFrom(velocity);
    scores = false;
  }

  bool free = false;

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    if (other is Doh || other is Wall) {
      contact.isEnabled = false;
    } else if (other is Ball) {
      other.body.linearVelocity.add(randomNormalizedVector2() * 5);
    }
  }

  @override
  onLoad() async {
    super.onLoad();
    animation = await sheetIWH('doh_disc.png', 16, 16);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (free) return;

    anim_time += dt;
    if (anim_time > 1.0) anim_time -= 1.0;

    state = EnemyState.spawned;
    forced_position.add(forced_velocity * dt);
    body.setTransform(forced_position, 0);
    if (position.distanceToSquared(visual.game_pixels / 2) > 800) {
      free = true;
      state = EnemyState.active;
      body.linearVelocity.setFrom(forced_velocity);
    }
  }
}
