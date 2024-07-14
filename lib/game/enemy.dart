import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'ball.dart';
import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'player.dart';
import 'soundboard.dart';

enum EnemyState {
  spawned,
  active,
  exploding,
}

abstract class Enemy extends BodyComponent with AutoDispose, ContactCallbacks {
  Enemy({required this.radius, this.hit_points = 5}) {
    priority = 5;
  }

  late final SpriteSheet animation;
  late final SpriteSheet explosion;

  EnemyState state = EnemyState.spawned;

  final forced_position = Vector2.zero();
  final forced_velocity = Vector2.zero();
  double anim_time = 0.0;
  double _explode_time = 0.0;

  double radius;
  int hit_points;

  bool scores = true;

  spawn_at(Vector2 position) {
    forced_position.setFrom(position);
    forced_velocity.setValues(0, 25);
    state = EnemyState.spawned;
  }

  void hit() {
    hit_points--;
    if (hit_points <= 0) {
      explode();
    } else {
      soundboard.note_index = 20;
      soundboard.trigger(Sound.wall_hit);
    }
  }

  explode() {
    if (state == EnemyState.exploding) return;

    if (scores) model.state.score += configuration.enemy_score;

    forced_position.setFrom(position);
    body.linearVelocity.setZero();

    state = EnemyState.exploding;
    _explode_time = 0.0;
    soundboard.play(Sound.enemy_destroyed);

    sendMessage(EnemyDestroyed());
  }

  // BodyComponent

  @override
  Body createBody() {
    renderBody = debug;
    paint.style = PaintingStyle.stroke;

    final shape = FixtureDef(
      CircleShape()..radius = radius,
      restitution: 1.0,
      density: 1,
    );

    final body = BodyDef(
      bullet: true,
      fixedRotation: true,
      gravityOverride: Vector2.zero(),
      userData: this,
      type: BodyType.dynamic,
    );

    return world.createBody(body)..createFixture(shape);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (state == EnemyState.exploding) {
      contact.isEnabled = false;
    } else if (other is Ball) {
      if (other.disruptor > 0) {
        contact.isEnabled = false;
        explode();
      } else {
        hit();
      }
    } else if (other is Player && other.state == PlayerState.playing) {
      explode();
    }
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    explosion = await sheetIWH('enemy_explosion.png', 16, 16);
    onMessage<EnterRound>((_) => removeFromParent());
    // handled by EnemySpawner instead to have teleports
    // onMessage<LevelComplete>((_) => removeFromParent());
  }

  @override
  void update(double dt) {
    if (renderBody != debug) renderBody = debug;
    if (phase != GamePhase.game_on) return;
    super.update(dt);
    switch (state) {
      case EnemyState.spawned:
        body.setTransform(forced_position, 0);
        if (body.position.y < 10) {
          forced_position.add(forced_velocity * dt);
          anim_time += dt;
          if (anim_time > 1.0) anim_time -= 1.0;
        } else {
          body.applyLinearImpulse(forced_velocity / dt);
          state = EnemyState.active;
        }

      case EnemyState.active:
        if (body.position.y > visual.game_pixels.y + 8) {
          removeFromParent();
        } else {
          anim_time += dt;
          if (anim_time > 1.0) anim_time -= 1.0;
        }
        if (body.linearVelocity.length > 100) {
          body.linearVelocity..normalize()..scale(100);
        }

      case EnemyState.exploding:
        body.setTransform(forced_position, 0);
        _explode_time += dt * 3;
        if (_explode_time > 1.0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_explode_time < 0.2) _render_sprite(canvas);
    if (state == EnemyState.exploding) _render_explosion(canvas);
  }

  void _render_sprite(Canvas canvas) {
    final frames = animation.columns * animation.rows;
    final frame = ((frames - 1) * anim_time).clamp(0, frames - 1).toInt();
    final sprite = animation.getSpriteById(frame);
    sprite.render(canvas, anchor: Anchor.center);
  }

  void _render_explosion(Canvas canvas) {
    final frames = explosion.columns * explosion.rows;
    final frame = ((frames - 1) * _explode_time).clamp(0, frames - 1).toInt();
    final sprite = explosion.getSpriteById(frame);
    sprite.render(canvas, anchor: Anchor.center);
  }
}
