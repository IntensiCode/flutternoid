import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutternoid/game/level.dart';
import 'package:flutternoid/game/player.dart';

import 'ball.dart';
import 'game_context.dart';

class Shadows extends Component {
  final Iterable<Ball> Function() balls;

  Shadows(this.balls);

  late final double _shadow_offset;

  final _render_pos = Vector2.zero();

  @override
  onLoad() => _shadow_offset = visual.shadow_offset;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (level.state != LevelState.waiting) {
      for (final row in level.brick_rows) {
        for (final brick in row) {
          if (brick == null) continue;
          _render_pos.setFrom(brick.topLeft);
          _render_pos.x += _shadow_offset;
          _render_pos.y += _shadow_offset;

          final progress = brick.destroy_progress.clamp(0.0, 1.0);
          final frame = (level.sprites.columns - 1) * progress;
          final sprite = level.sprites.getSpriteById(20 + frame.round().clamp(0, level.sprites.columns));
          sprite.render(canvas, position: _render_pos, overridePaint: level.paint);
        }
      }
    }

    for (final ball in balls()) {
      if (ball.state != BallState.active) continue;
      _render_pos.setFrom(ball.position);
      _render_pos.x += _shadow_offset;
      _render_pos.y += _shadow_offset;

      final sprite = ball.sprites.getSpriteById(1);
      sprite.render(canvas, position: _render_pos, anchor: Anchor.center, overridePaint: ball.paint);
    }

    if (player.state != PlayerState.gone) {
      _render_pos.setFrom(player.position);
      _render_pos.x += _shadow_offset;
      _render_pos.y += _shadow_offset;

      final sprite = player.sprites.getSpriteById(9 + player.mode.index);
      sprite.render(canvas, position: _render_pos, anchor: Anchor.center, overridePaint: player.paint);
    }
  }
}
