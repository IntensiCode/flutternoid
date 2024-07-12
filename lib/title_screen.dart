import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutternoid/components/flow_text.dart';
import 'package:flutternoid/util/fonts.dart';

import 'core/common.dart';
import 'core/screens.dart';
import 'game/soundboard.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/bitmap_button.dart';
import 'util/effects.dart';
import 'util/extensions.dart';

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static const x = 243.0;
  static const y = 42.0;

  static bool seen = false;

  @override
  onLoad() async {
    await spriteXY('title.png', xCenter, yCenter);

    final delta = seen ? 0.0 : 0.2;
    at(delta, () async => await add(fadeIn(await _controls())));
    at(delta, () async => await add(fadeIn(await _hiscore())));
    at(delta, () async => await add(fadeIn(await _audio())));
    at(delta, () async => await add(fadeIn(await _video())));
    at(delta, () async => await add(fadeIn(await _credits())));
    at(delta, () async => await added(await _insert_coin()).add(BlinkEffect()));

    final cheats = [
      'Laser :: 1',
      'Catcher :: 2',
      'Expander :: 3',
      'Disruptor :: 4',
      'Slow Down :: 5',
      'Multi Ball :: 6',
      'Extra Life :: 7',
      'Add Ball :: b',
      'Reset Balls :: r',
      'Level Complete :: c or n',
      'Game Over :: x',
      'Next Level :: j <S-j> <C-j>',
      'Prev Level :: k <S-k> <C-k>',
      '',
      'Only during game play',
    ].join('\n');
    add(_cheats = FlowText(
      text: cheats,
      font: tiny_font,
      insets: Vector2(5,6),
      position: Vector2(0, 64),
      anchor: Anchor.topLeft,
      size: Vector2(120, 112),
    ));
    _cheats.isVisible = dev;
  }

  late final FlowText _cheats;

  @override
  void onMount() {
    super.onMount();
    if (!seen) soundboard.play_one_shot_sample('arkanoid.ogg');
    if (!seen) soundboard.play_music('music/theme.mp3');
    // onKey('<Space>', () => _showScreen(Screen.game)); handled by _insert_coin below
    seen = true;

    onKey('t', () => _cheat += 't');
    onKey('f', () => _cheat += 'f');
    onKey('d', () => _cheat += 'd');
    onKey('j', () => _cheat += 'j');
  }

  String _cheat = '';

  @override
  void update(double dt) {
    super.update(dt);
    if (_cheat.length > 4) _cheat = _cheat.substring(1);
    if (_cheat == 'tfdj') {
      dev = !dev;
      logInfo('dev mode $dev');
      _cheats.isVisible = dev;
      _cheat = '';
    }
  }

  // Implementation

  void _showScreen(Screen it) {
    if (it == Screen.game) soundboard.fade_out_music();
    showScreen(it);
  }

  Future<BitmapButton> _controls() async => await button(
        text: 'How To Play',
        position: Vector2(x, y),
        anchor: Anchor.topLeft,
        shortcuts: ['p', '?'],
        onTap: (_) => _showScreen(Screen.help),
      );

  Future<BitmapButton> _hiscore() => button(
        text: '   Hiscore   ',
        position: Vector2(x, y + 16),
        anchor: Anchor.topLeft,
        shortcuts: ['h'],
        onTap: (_) => _showScreen(Screen.hiscore),
      );

  Future<BitmapButton> _audio() => button(
        text: '     Audio     ',
        position: Vector2(x, y + 32),
        anchor: Anchor.topLeft,
        shortcuts: ['a'],
        onTap: (_) => _showScreen(Screen.audio_menu),
      );

  Future<BitmapButton> _video() => button(
        text: '     Video     ',
        position: Vector2(x, y + 48),
        anchor: Anchor.topLeft,
        shortcuts: ['v'],
        onTap: (_) => _showScreen(Screen.video_menu),
      );

  Future<BitmapButton> _credits() => button(
        text: '   Credits   ',
        position: Vector2(x, y + 64),
        anchor: Anchor.topLeft,
        shortcuts: ['c'],
        onTap: (_) => _showScreen(Screen.credits),
      );

  Future<BitmapButton> _insert_coin() => button(
        text: 'Insert coin',
        fontScale: 2,
        position: Vector2(xCenter, gameHeight - 16),
        anchor: Anchor.center,
        shortcuts: ['<Space>'],
        onTap: (_) => _showScreen(Screen.game),
      );
}
