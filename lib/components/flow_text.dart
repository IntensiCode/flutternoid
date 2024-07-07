import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutternoid/core/functions.dart';
import 'package:flutternoid/util/nine_patch_image.dart';

import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';

class FlowText extends PositionComponent with AutoDispose, GameScriptFunctions {
  //
  late final List<String> _lines;
  late final int _visible_lines;
  final BitmapFont _font;
  final double _font_scale;
  final Vector2 _insets;

  late final double _line_height;
  final List<BitmapText> _showing = [];

  FlowText({
    required String text,
    required BitmapFont font,
    double font_scale = 1,
    Vector2? insets,
    required Vector2 size,
    super.position,
    super.anchor,
    super.scale,
  })  : _font = font,
        _font_scale = font_scale,
        _insets = insets ?? Vector2(4, 4),
        super(size: size) {
    //
    final avail_width = size.x - _insets.x * 2;
    _lines = text.lines().map((it) => _font.reflow(it, avail_width.toInt(), scale: _font_scale)).flattened.toList();

    _line_height = _font.lineHeight(_font_scale) * 1.1;
    _visible_lines = (size.y - _insets.y * 2) ~/ _line_height;
  }

  @override
  onLoad() async {
    add(NinePatchComponent(image: await image('button_plain.png'), size: size));
    _update_shown_lines();
  }

  void _update_shown_lines() {
    _showing.forEach((it) => it.removeFromParent());
    _showing.clear();

    final add_pos = Vector2.copy(_insets);
    final lines = _lines.take(_visible_lines).map((line) {
      final it = BitmapText(text: line, font: _font, anchor: Anchor.topLeft, position: add_pos, scale: _font_scale);
      add_pos.y += _line_height;
      return it;
    });

    _showing.addAll(lines);
    _showing.forEach(add);
  }
}