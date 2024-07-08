import 'dart:ui';

import 'package:kart/kart.dart';

import '../core/common.dart';
import '../util/bitmap_font.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'game_context.dart';
import 'game_object.dart';
import 'game_particles.dart';

class FlashText extends GameParticles<_FlashLetter> {
  FlashText() : super(_FlashLetter.new);

  static const _font_scale = 0.5;

  late final BitmapFont _font;

  final _queue = <(String, double, double)>[];
  var _dequeue = 0.0;

  void spawn(String text, [double? x, double? y]) {
    x ??= player.position.x;
    y ??= player.position.y;
    if (_queue.isEmpty) _trigger(text, x, y + player.bat_height);
    _queue.add((text, x, y));
    _dequeue = 0.25;
  }

  void _trigger(String text, double x, double y) {
    _font.scale = _font_scale;

    final length = text.length;
    final width = _font.lineWidth(text);
    for (int idx = 0; idx < length; idx++) {
      final partial = text.substring(0, idx);
      final offset = _font.lineWidth(partial);
      require_particle()
        ..init(text.codeUnitAt(idx))
        ..init_position(x - width / 2 + offset, y)
        ..init_timing(tps * idx ~/ length, tps)
        ..activate();
    }
  }

  // Component

  @override
  onLoad() {
    priority = 5;

    _font = tinyFont;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_dequeue > 0) {
      _dequeue -= dt;
      if (_dequeue <= 0) {
        _dequeue = 0;
        _queue.removeAt(0);
        _dequeue = _queue.isEmpty ? 0 : 1;
        if (_queue.isNotEmpty) {
          final (text, x, y) = _queue.getOrNull(0)!;
          _trigger(text, x, y);
        }
      }
    }
  }

  @override
  render(Canvas canvas) {
    _font.scale = _font_scale;
    for (final it in active_particles) {
      _font.paint.opacity = it.opacity;
      _font.drawString(canvas, it.x, it.y, String.fromCharCode(it.char_code));
    }
  }
}

enum _FlashState {
  fade_in,
  hold,
  fade_out,
}

class _FlashLetter with HasGameData, GameParticle, ManagedGameParticle {
  @override
  bool get loop => false;

  int char_code = 0;

  double speed = 0;
  double opacity = 0;
  double hold = 0;

  var _flashState = _FlashState.fade_in;

  void init(int char_code) {
    this.char_code = char_code;
    this.speed = 0;
    this.opacity = 0;
    this.hold = 0;
    this._flashState = _FlashState.fade_in;
  }

  // GameParticle

  @override
  void update_while_active() {
    if (_flashState != _FlashState.fade_in) {
      speed += 50.0 / tps;
      y += speed / tps;
    }

    if (_flashState == _FlashState.fade_in) {
      opacity += 4.0 / tps;
      if (opacity >= 1) {
        opacity = 1;
        _flashState = _FlashState.hold;
      }
    }

    if (_flashState == _FlashState.hold) {
      hold += 2.0 / tps;
      if (hold >= 1) {
        hold = 1;
        _flashState = _FlashState.fade_out;
      }
    }

    if (_flashState == _FlashState.fade_out) {
      opacity -= 4.0 / tps;
      if (opacity <= 0) {
        opacity = 0;
        active = false;
      }
    }
  }

  // HasGameData

  @override
  void load_state(GameData data) {
    super.load_state(data);
    // char_code = data['char_code'];
    // char_index = data['char_index'];
    // text_length = data['text_length'];
    // speed_y = data['speed_y'];
  }

  @override
  GameData save_state(GameData data) => super.save_state(data);
// ..['char_code'] = char_code
// ..['char_index'] = char_index
// ..['text_length'] = text_length
// ..['speed_y'] = speed_y);
}
