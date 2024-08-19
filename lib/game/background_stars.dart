import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';
import 'game_context.dart';

class BackgroundStars extends PositionComponent with GameContext, HasPaint {
  BackgroundStars() {
    priority = -5;
  }

  late final FragmentShader shader;

  double _anim_time = 0.0;

  // Component

  @override
  onLoad() async {
    super.onLoad();
    shader = (await FragmentProgram.fromAsset('assets/shaders/stars.frag')).fragmentShader();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;
  }

  final shader_paint = pixelPaint();

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    shader.setFloat(0, gameWidth);
    shader.setFloat(1, gameHeight);
    shader.setFloat(2, -_anim_time);

    shader_paint.shader = shader;

    if (!visual.animate_stars) {
      if (_snapshot != null) {
        canvas.drawImage(_snapshot!, Offset.zero, paint);
      } else {
        _render(canvas, 0, 319, shader_paint, snapshot: true);
      }
      return;
    } else {
      _render(canvas, 0, 319, shader_paint);
    }
  }

  Image? _snapshot;

  void _render(Canvas canvas, double from, double w, Paint shader_paint, {bool snapshot = false}) {
    const h = gameHeight - 1;

    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w, h), shader_paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(w ~/ 1, h ~/ 1);
    canvas.drawImage(image, Offset(from, 0), paint);
    if (snapshot) {
      _snapshot?.dispose();
      _snapshot = image;
    } else {
      image.dispose();
    }
    picture.dispose();
  }
}
