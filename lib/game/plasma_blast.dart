import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flutter/foundation.dart';

import '../core/common.dart';
import '../core/random.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'game_context.dart';
import 'game_messages.dart';

class PlasmaBlasts extends Component with AutoDispose, GameContext, HasPaint {
  late final FragmentShader _shader;

  final _active = <_Blast>[];

  PlasmaBlasts() {
    priority = 10;
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    _shader = (await FragmentProgram.fromAsset('assets/shaders/plasma.frag')).fragmentShader();
    onMessage<TriggerPlasmaBlast>((it) => _active.add(_Blast(it.ball)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final it in _active) {
      it.update(dt);
    }
    _active.removeWhere((it) => it.expired);
  }

  final shader_paint = pixelPaint();

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _shader.setFloat(0, visual.plasma_size.x);
    _shader.setFloat(1, visual.plasma_size.y);
    _shader.setFloat(2, 0);

    for (final it in _active) {
      _shader.setFloat(2, it.anim_time);
      shader_paint.shader = _shader;
      _render_blast(canvas, it);
    }
  }

  void _render_blast(Canvas canvas, _Blast blast) {
    final w = visual.plasma_size.x;
    final h = visual.plasma_size.y;
    final x = blast.ball.position.x - w / 2;
    final y = blast.ball.position.y - h / 2;

    shader_paint.opacity = blast.opacity;

    if (visual.pixelate) {
      final recorder = PictureRecorder();
      Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w, h), shader_paint);

      final picture = recorder.endRecording();
      final image = picture.toImageSync(w.toInt(), h.toInt());
      canvas.drawImage(image, Offset(x, y), paint);
      image.dispose();
      picture.dispose();
    } else {
      canvas.translate(x, y);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), shader_paint);
    }
  }
}

class _Blast {
  final BodyComponent ball;
  final double anim_base = rng.nextDoubleLimit(10);
  double anim_time = 0;
  bool expired = false;

  _Blast(this.ball);

  double get opacity => switch (anim_time) {
        < 0.2 => (anim_time * 5).clamp(0.0, 1.0),
        > 0.5 => (1.0 - (anim_time - 0.5) * 2).clamp(0.0, 1.0),
        _ => 1.0,
      };

  update(double dt) {
    anim_time += dt;
    if (anim_time > 1.0) expired = true;
  }
}
