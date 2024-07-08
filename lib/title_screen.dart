import 'package:flame/components.dart';
import 'package:flutternoid/core/soundboard.dart';

import 'core/common.dart';
import 'core/screens.dart';
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
    soundboard.preload();

    await spriteXY('title.png', xCenter, yCenter);

    final delta = seen ? 0.0 : 0.2;
    at(delta, () async => await add(fadeIn(await _controls())));
    at(delta, () async => await add(fadeIn(await _hiscore())));
    at(delta, () async => await add(fadeIn(await _audio())));
    at(delta, () async => await add(fadeIn(await _video())));
    at(delta, () async => await add(fadeIn(await _credits())));
    at(delta, () async => await added(await _insert_coin()).add(BlinkEffect()));
  }

  @override
  void onMount() {
    super.onMount();
    if (!seen) soundboard.play_one_shot_sample('arkanoid.ogg');
    if (!seen) soundboard.play_music('music/theme.mp3');
    onKey('<Space>', () => _showScreen(Screen.game));
    seen = true;
  }

  // Implementation

  void _showScreen(Screen it) {
    // TODO if (it == Screen.game) fade to in-game music
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
