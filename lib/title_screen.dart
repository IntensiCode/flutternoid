import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'game/game_dialog.dart';
import 'game/game_state.dart';
import 'game/soundboard.dart';
import 'help_screen.dart';
import 'input/game_keys.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/bitmap_button.dart';
import 'util/effects.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static const x = 243.0;
  static const y = 42.0;

  static bool seen = false;
  static bool music = false;
  static bool first_time_playing = false;

  @override
  onLoad() async {
    if (help_triggered_at_first_start) {
      help_triggered_at_first_start = false;
      if (music) soundboard.fade_out_music();
      showScreen(Screen.game);
      return;
    }

    soundboard.preload();

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
      insets: Vector2(5, 5),
      position: Vector2(0, 66),
      anchor: Anchor.topLeft,
      size: Vector2(120, 112 - 8),
    ));
    _cheats.isVisible = dev;

    try {
      await state.preload();
    } catch (ignored) {
      logError('error loading game state: $ignored');
    }

    try {
      first_time_playing = await first_time();
      logInfo('first time playing? $first_time_playing');
      if (first_time_playing || state.level_number_starting_at_1 == 1) {
        await state.delete();
        state.reset();
      }
    } catch (ignored) {
      logError('error loading first time playing state: $ignored');
    }
  }

  late final FlowText _cheats;

  @override
  void onMount() {
    super.onMount();
    if (!seen) music = true;
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
    if (children.whereType<GameDialog>().isNotEmpty) return;

    if (it == Screen.game) {
      if (state.level_number_starting_at_1 > 1) {
        add(GameDialog(
          {
            GameKey.soft1: () async {
              await state.delete();
              await state.reset();
              if (music) soundboard.fade_out_music();
              showScreen(Screen.game);
            },
            GameKey.soft2: () {
              if (music) soundboard.fade_out_music();
              showScreen(Screen.game);
            },
          },
          'Game in progress.\n\nResume game?\n\nOr start new game?',
          'New Game',
          'Resume Game',
          flow_text: true,
          shortcuts: true,
        ));
        return;
      } else if (first_time_playing) {
        help_triggered_at_first_start = true;
        showScreen(Screen.help);
        return;
      }
    }

    if (it == Screen.game) if (music) soundboard.fade_out_music();
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
