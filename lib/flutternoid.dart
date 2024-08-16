import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Image, Shortcuts;

import 'core/common.dart';
import 'core/messaging.dart';
import 'core/screens.dart';
import 'game/soundboard.dart';
import 'game/visual_configuration.dart';
import 'input/shortcuts.dart';
import 'main_controller.dart';
import 'util/fonts.dart';
import 'util/performance.dart';

class Flutternoid extends Forge2DGame<MainController>
    with HasKeyboardHandlerComponents, Messaging, Shortcuts, HasPerformanceTracker, ScrollDetector, SingleGameInstance {
  //
  Flutternoid() : super(world: MainController()) {
    game = this;
    world = this.world;
    images = this.images;
    if (kIsWeb) logAnsi = false;
  }

  @override
  onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: gameWidth,
      height: gameHeight,
      hudComponents: [_ticks(), _frames()],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  _ticks() => RenderTps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );

  _frames() => RenderFps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 8),
        anchor: Anchor.topLeft,
      );

  @override
  onLoad() async {
    super.onLoad();

    atlas = await game.atlasFromAssets('flutternoid.atlas');

    // soundboard.preload();
    await loadFonts(assets);

    add(soundboard);

    if (dev) {
      onKey('<A-->', () => _slowDown());
      onKey('<A-=>', () => _speedUp());
      onKey('<A-S-+>', () => _speedUp());
      onKey('<A-a>', () => showScreen(Screen.audio_menu));
      onKey('<A-c>', () => showScreen(Screen.credits));
      onKey('<A-e>', () => showScreen(Screen.end));
      onKey('<A-d>', () => _toggleDebug());
      onKey('<A-g>', () => showScreen(Screen.game));
      onKey('<A-h>', () => showScreen(Screen.hiscore));
      onKey('<A-l>', () => showScreen(Screen.loading));
      onKey('<A-m>', () => soundboard.toggleMute());
      onKey('<A-p>', () => showScreen(Screen.help));
      onKey('<A-t>', () => showScreen(Screen.title));
      onKey('<A-v>', () => showScreen(Screen.video_menu));
    }
  }

  _toggleDebug() {
    visual.debug = !visual.debug;
    return KeyEventResult.handled;
  }

  _slowDown() {
    if (_timeScale > 0.125) _timeScale /= 2;
  }

  _speedUp() {
    if (_timeScale < 4.0) _timeScale *= 2;
  }

  double _timeScale = 1;

  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);
    if (info.scrollDelta.global.y == 0) return;
    send(MouseWheel(info.scrollDelta.global.y.sign));
  }
}
