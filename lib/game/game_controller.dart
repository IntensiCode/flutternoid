import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/screens.dart';
import '../input/keys.dart';
import '../input/shortcuts.dart';
import '../scripting/game_script.dart';
import '../util/bitmap_button.dart';
import '../util/fonts.dart';
import '../util/on_message.dart';
import 'background_stars.dart';
import 'doh_intro.dart';
import 'game_context.dart';
import 'game_dialog.dart';
import 'game_messages.dart';
import 'game_over.dart';
import 'game_phase.dart';
import 'game_screen.dart';

class GameController extends GameScriptComponent with HasAutoDisposeShortcuts {
  final _keys = Keys();
  final _stars = BackgroundStars();

  late final Image _button;
  late final _game = GameScreen(keys: _keys);

  Component? _overlay;

  @override
  onLoad() async {
    super.onLoad();

    _button = await image('button_plain.png');

    await add(_stars);
    await add(_keys);
    await add(_game);

    if (_game.phase == GamePhase.doh_intro) {
      _stars.split_mode = false;
      await add(_overlay = DohIntro(_on_game_on));
    } else {
      _on_game_on();
    }
  }

  @override
  onMount() {
    super.onMount();
    onMessage<GamePhaseUpdate>((it) {
      if (it.phase == GamePhase.game_over) _on_game_over();
    });
  }

  _on_game_on() {
    _stars.split_mode = true;
    _overlay?.removeFromParent();
    _overlay = null;
    _game.phase = GamePhase.game_on;
    _overlay = Component(children: [
      BitmapButton(
        bgNinePatch: _button,
        text: 'Exit',
        position: Vector2(0, 32),
        anchor: Anchor.topLeft,
        font: tinyFont,
        onTap: (_) => _on_confirm_exit(),
      )..angle = -pi / 2,
      BitmapButton(
        bgNinePatch: _button,
        text: 'Pause',
        position: Vector2(0, gameHeight + 16),
        anchor: Anchor.bottomLeft,
        font: tinyFont,
        onTap: (_) => _on_game_paused(),
      )..angle = -pi / 2,
    ]);
    add(_overlay!);
  }

  _on_game_paused() {
    _overlay?.removeFromParent();
    _overlay = null;
    _game.phase = GamePhase.game_paused;
    _overlay = GameDialog(_on_key[GamePhase.game_paused]!, 'Game paused', 'Exit', 'Resume');
    add(_overlay!);
  }

  _on_confirm_exit() {
    _overlay?.removeFromParent();
    _overlay = null;
    _game.phase = GamePhase.confirm_exit;
    _overlay = GameDialog(_on_key[GamePhase.confirm_exit]!, 'Back to title?', 'Yes', 'No');
    add(_overlay!);
  }

  _on_game_over() {
    _overlay?.removeFromParent();
    _overlay = null;
    _overlay = GameOver(_on_key[GamePhase.game_over]!);
    add(_overlay!);
  }

  late final _on_key = {
    GamePhase.doh_intro: {
      GameKey.soft1: () => _on_game_on(),
      GameKey.soft2: () => _on_game_on(),
      GameKey.fire1: () => _on_game_on(),
      GameKey.fire2: () => _on_game_on(),
    },
    GamePhase.game_on: {
      GameKey.soft1: () => _on_confirm_exit(),
      GameKey.soft2: () => _on_game_paused(),
    },
    GamePhase.game_paused: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => _on_game_on(),
    },
    GamePhase.game_over: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => showScreen(Screen.title),
    },
    GamePhase.confirm_exit: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => _on_game_on(),
    },
  };

  @override
  void update(double dt) {
    super.update(dt);

    final mapping = _on_key[_game.phase];
    for (final key in mapping!.keys) {
      if (_keys.check_and_consume(key)) mapping[key]!();
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (visual.pixelate && false) {
      final recorder = PictureRecorder();
      super.renderTree(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(gameWidth ~/ 1, gameHeight ~/ 1);
      canvas.drawImage(image, Offset.zero, pixelPaint());
      image.dispose();
      picture.dispose();
    } else {
      super.renderTree(canvas);
    }
  }
}
