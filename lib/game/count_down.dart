import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutternoid/game/soundboard.dart';
import 'package:flutternoid/util/fonts.dart';

import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'game_context.dart';
import 'game_messages.dart';

class CountDown extends PositionComponent with AutoDispose, GameContext, HasPaint {
  int? _count;
  double _anim = 0;

  CountDown() {
    priority = 100;
    anchor = Anchor.center;
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    onMessage<ShowCountDown>((it) {
      scale.setAll(1);
      opacity = 0.75;
      _count = it.count;
      _anim = 1;
      soundboard.play_one_shot_sample('sound/$_count.ogg');
    });
  }

  @override
  void onMount() {
    super.onMount();
    position.x = visual.game_pixels.x / 2;
    position.y = visual.game_pixels.y / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_count == null || _anim == 0) return;
    _anim -= min(_anim, dt * 1.25);
    if (_anim <= 0) _count = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_count == null) return;

    final d = (1 - _anim);
    scale.setAll(1 + d * d * d* 5);

    opacity = _anim * 0.75;

    final saved = mini_font.paint;
    mini_font.paint = paint;
    mini_font.drawStringAligned(canvas, 0, 0, _count.toString(), Anchor.center);
    mini_font.paint = saved;
  }
}
