import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import 'ball.dart';
import 'game_messages.dart';
import 'soundboard.dart';

class Doh extends BodyComponent with AutoDispose, ContactCallbacks {
  Doh(Vector2 center) : _spawn_pos = center;

  final Vector2 _spawn_pos;

  late final SpriteSheet _sprites;

  int hits = 33;

  bool vanishing = false;
  double vanish_time = 0;

  // BodyComponent

  @override
  Body createBody() {
    // renderBody = debug;
    paint.style = PaintingStyle.stroke;

    final body = BodyDef(
      bullet: false,
      fixedRotation: true,
      gravityOverride: Vector2.zero(),
      position: _spawn_pos,
      userData: this,
      type: BodyType.static,
    );

    return world.createBody(body)
      ..createFixtureFromShape(PolygonShape()..setAsBox(12, 21, Vector2(0, 2), 0), restitution: 1)
      ..createFixtureFromShape(PolygonShape()..setAsBox(15, 3, Vector2(0, 19), 0), restitution: 1)
      ..createFixtureFromShape(PolygonShape()..setAsBox(14, 1, Vector2(0, 10), 0), restitution: 1)
      ..createFixtureFromShape(PolygonShape()..setAsBox(14, 3, Vector2(0, -5), 0), restitution: 1)
      ..createFixtureFromShape(
          PolygonShape()
            ..set([
              Vector2(-12, -19),
              Vector2(-5, -23),
              Vector2(5, -23),
              Vector2(12, -19),
            ]),
          density: 100000,
          restitution: 1);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      if (hits > 0) {
        hits--;
        if (hits < 10) {
          soundboard.play(Sound.doh_ugh);
        } else {
          soundboard.note_index = 0;
          soundboard.play(Sound.wall_hit);
        }
        other.body.linearVelocity.scale(1.05);
      } else {
        vanishing = true;
        soundboard.play_one_shot_sample('doh_no.ogg');
      }
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    _sprites = await sheetIWH('doh.png', 32, 47);
  }

  @override
  void update(double dt) {
    super.update(dt);
    renderBody = debug;

    if (vanishing) {
      vanish_time += dt / 2;
      if (vanish_time >= 1.0) {
        sendMessage(GameComplete());
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final frame = vanish_time * (_sprites.columns - 1);
    final sprite = _sprites.getSpriteById(frame.round());
    _paint.opacity = (1 - vanish_time).clamp(0, 1);
    sprite.render(canvas, anchor: Anchor.center, overridePaint: _paint);
  }

  final _paint = pixelPaint();
}
