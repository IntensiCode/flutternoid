import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import 'bitmap_font.dart';
import 'fonts.dart';

class BitmapText extends PositionComponent with HasPaint, HasVisibility {
  final String text;
  final BitmapFont font;
  final double fontScale;
  Image? _snapshot;

  BitmapText({
    required this.text,
    required Vector2 position,
    BitmapFont? font,
    double scale = 1,
    Color? tint,
    Anchor anchor = Anchor.topLeft,
  })  : font = font ?? mini_font,
        fontScale = scale {
    paint = pixelPaint();
    if (tint != null) this.tint(tint);
    this.position.setFrom(position);
    this.font.scale = fontScale;
    final w = this.font.lineWidth(text);
    final h = this.font.lineHeight(fontScale);
    final x = anchor.x * w;
    final y = anchor.y * h;
    this.position.x -= x;
    this.position.y -= y;
    size.setValues(max(0, w), max(0, h));
  }

  @override
  void onRemove() {
    super.onRemove();
    _snapshot?.dispose();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x == 0 || size.y == 0) {
      logError('invalid size for $this, size $size, text $text');
      removeFromParent();
      return;
    }
    try {
      _snapshot ??= _render_snapshot();
      canvas.scale(fontScale);
      canvas.drawImage(_snapshot!, Offset.zero, paint);
    } catch (it, trace) {
      logError(size);
      logError('snapshot failed for $this, size $size, text $text: $it', trace);
      removeFromParent();
    }
  }

  Image _render_snapshot() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = pixelPaint();

    font.paint.color = paint.color;
    font.paint.colorFilter = paint.colorFilter;
    font.paint.filterQuality = FilterQuality.none;
    font.paint.isAntiAlias = false;
    font.paint.blendMode = paint.blendMode;
    font.scale = 1; // fontScale;
    font.drawString(canvas, 0, 0, text);

    final width = size.x / fontScale;
    final height = size.y / fontScale;
    final picture = recorder.endRecording();
    final result = picture.toImageSync(width.toInt(), height.toInt());
    picture.dispose();
    return result;
  }
}
