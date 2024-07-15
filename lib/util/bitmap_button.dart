import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../input/shortcuts.dart';
import '../util/auto_dispose.dart';
import 'bitmap_font.dart';
import 'bitmap_text.dart';
import 'extensions.dart';
import 'fonts.dart';
import 'nine_patch_image.dart';

Future<BitmapButton> button({
  Image? bgNinePatch,
  required String text,
  int cornerSize = 8,
  Vector2? position,
  Vector2? size,
  BitmapFont? font,
  Anchor? anchor,
  List<String> shortcuts = const [],
  double fontScale = 1,
  Color? tint,
  required Function(BitmapButton) onTap,
}) async =>
    BitmapButton(
      bgNinePatch: bgNinePatch ?? await image('button_plain.png'),
      text: text,
      cornerSize: cornerSize,
      position: position,
      size: size,
      font: font,
      anchor: anchor,
      shortcuts: shortcuts,
      fontScale: fontScale,
      tint: tint,
      onTap: onTap,
    );

class BitmapButton extends PositionComponent
    with AutoDispose, HasPaint, HasVisibility, TapCallbacks, HasAutoDisposeShortcuts {
  //
  final NinePatchImage? background;
  final String text;
  final BitmapFont font;
  final double fontScale;
  final int cornerSize;
  final Function(BitmapButton) onTap;
  final List<String> shortcuts;

  late final NinePatchComponent _bg;
  late final BitmapText _text;

  Image? _snapshot;

  BitmapButton({
    Image? bgNinePatch,
    required this.text,
    this.cornerSize = 8,
    Vector2? position,
    Vector2? size,
    BitmapFont? font,
    Anchor? anchor,
    this.shortcuts = const [],
    this.fontScale = 1,
    Color? tint,
    required this.onTap,
  })  : font = font ?? tiny_font,
        background = bgNinePatch != null ? NinePatchImage(bgNinePatch, cornerSize: cornerSize) : null {
    paint = pixelPaint();

    if (position != null) this.position.setFrom(position);
    if (tint != null) this.tint(tint);
    if (size == null) {
      this.font.scale = fontScale;
      this.size = this.font.textSize(text);
      this.size.x = (this.size.x ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
      this.size.y = (this.size.y ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
    } else {
      this.size = size;
    }
    final a = anchor ?? Anchor.center;
    final x = a.x * this.size.x;
    final y = a.y * this.size.y;
    this.position.x -= x;
    this.position.y -= y;
    if (bgNinePatch != null) {
      add(_bg = NinePatchComponent(
        image: bgNinePatch,
        size: this.size,
        cornerSize: 8,
      ));
    }
    add(_text = BitmapText(
      text: text,
      font: this.font,
      scale: fontScale,
      position: this.size / 2,
      anchor: Anchor.center,
    ));
  }

  @override
  void onMount() {
    super.onMount();
    onKeys(shortcuts, () => onTap(this));
  }

  @override
  void onRemove() {
    super.onRemove();
    _snapshot?.dispose();
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
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
    _bg.paint.opacity = 1;
    _text.paint.opacity = 1;
    super.renderTree(canvas);
    final picture = recorder.endRecording();
    final result = picture.toImageSync(width.toInt(), height.toInt());
    picture.dispose();
    return result;
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(this);
}
