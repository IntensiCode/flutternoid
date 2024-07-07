import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutternoid/util/auto_dispose.dart';
import 'package:flutternoid/util/on_message.dart';

import '../core/common.dart';
import '../core/random.dart';
import '../util/extensions.dart';
import 'game_context.dart';

class PlasmaBlasts extends Component with AutoDispose, HasPaint {
  late final FragmentShader _shader;

  final _active = <_Blast>[];

  PlasmaBlasts() {
    priority = 10;
  }

  trigger(Vector2 center) => _active.add(_Blast(center));

  // Component

  @override
  onLoad() async {
    super.onLoad();
    _shader = (await FragmentProgram.fromAsset('assets/shaders/plasma.frag')).fragmentShader();
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<TriggerPlasmaBlast>((it) => _active.add(_Blast(it.center)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final it in _active) {
      it.update(dt);
    }
    _active.removeWhere((it) => it.expired);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _shader.setFloat(0, visual.plasma_size.x);
    _shader.setFloat(1, visual.plasma_size.y);
    _shader.setFloat(2, 0);

    for (final it in _active) {
      _shader.setFloat(2, it.anim_time);

      final shader_paint = pixelPaint();
      shader_paint.shader = _shader;

      _render_blast(canvas, it, shader_paint);
    }
  }

  void _render_blast(Canvas canvas, _Blast blast, Paint shader_paint) {
    final w = visual.plasma_size.x;
    final h = visual.plasma_size.y;
    final x = blast.center.x - w / 2;
    final y = blast.center.y - h / 2;

    final shader_paint = pixelPaint();
    shader_paint.shader = _shader;
    shader_paint.opacity = blast.opacity;

    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w, h), shader_paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(w.toInt(), h.toInt());
    canvas.drawImage(image, Offset(x, y), paint);
    image.dispose();
    picture.dispose();
  }
}

class _Blast {
  final Vector2 center;
  final double anim_base = rng.nextDoubleLimit(10);
  double anim_time = 0;
  bool expired = false;

  _Blast(this.center);

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
