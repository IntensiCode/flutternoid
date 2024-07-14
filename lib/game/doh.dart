import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutternoid/core/random.dart';
import 'package:flutternoid/game/doh_disc.dart';
import 'package:flutternoid/game/game_context.dart';
import 'package:flutternoid/util/on_message.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import 'ball.dart';
import 'game_messages.dart';
import 'soundboard.dart';

class Doh extends BodyComponent with AutoDispose, ContactCallbacks, GameContext {
  Doh(Vector2 center) : _spawn_pos = center;

  final Vector2 _spawn_pos;

  late final SpriteSheet _sprites;

  int hits = 33;

  double appear_time = 0;
  bool vanishing = false;
  double vanish_time = 0;
  double fire_time = 2;

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
      } else if (!vanishing) {
        vanishing = true;
        soundboard.play_one_shot_sample('doh_no.ogg');
        sendMessage(DohVanishing());
      }
    } else {
      contact.isEnabled = false;
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    _sprites = await sheetIWH('doh.png', 32, 47);
    onMessage<GameComplete>((_) => removeFromParent());
    onMessage<LevelDataAvailable>((_) {
      if (level.doh == null) removeFromParent();
    });
    soundboard.play_one_shot_sample('doh_laugh.ogg');
  }

  @override
  void update(double dt) {
    super.update(dt);
    renderBody = debug;

    if (appear_time < 1.0) {
      appear_time += dt / 2;
      if (appear_time >= 1.0) {
        appear_time = 1;
      }
    } else if (vanishing) {
      vanish_time += dt / 2;
      if (vanish_time >= 1.0) {
        sendMessage(GameComplete());
      }
    } else {
      fire_time -= dt;
      if (fire_time <= 0) {
        fire_time = 2 + rng.nextDoubleLimit(2);
        final start = visual.game_pixels / 2;
        final velocity = Vector2.zero();
        velocity.setFrom(player.position);
        velocity.sub(start);
        velocity.normalize();
        velocity.scale(22.5);
        spawn_top_level(DohDisc(start, velocity));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final frame = vanish_time * (_sprites.columns - 1);
    final sprite = _sprites.getSpriteById(frame.round());
    _paint.opacity = (appear_time - vanish_time).clamp(0, 1);
    sprite.render(canvas, anchor: Anchor.center, overridePaint: _paint);
  }

  final _paint = pixelPaint();
}
