import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../util/extensions.dart';
import 'components/basic_menu.dart';
import 'components/basic_menu_button.dart';
import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'game/visual_configuration.dart';
import 'input/game_keys.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

enum OptionsMenuEntry {
  pixelate,
  pixelate_screen,
}

class Options extends GameScriptComponent with HasAutoDisposeShortcuts, KeyboardHandler, HasGameKeys {
  static OptionsMenuEntry? rememberSelection;

  late final BasicMenuButton pixelate;
  late final BasicMenuButton pixelate_screen;

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('Video Mode', xCenter, 16, scale: 2);

    final buttonSheet = await sheetI('button_option.png', 1, 2);
    final menu = added(BasicMenu<OptionsMenuEntry>(buttonSheet, tiny_font, _selected));
    pixelate = menu.addEntry(OptionsMenuEntry.pixelate, 'Pixelate FX', anchor: Anchor.centerLeft);
    pixelate_screen = menu.addEntry(OptionsMenuEntry.pixelate_screen, 'Pixelate Game Screen', anchor: Anchor.centerLeft);

    pixelate.checked = visual.pixelate;
    pixelate_screen.checked = visual.pixelate_screen;

    menu.position.setValues(xCenter, yCenter);
    menu.anchor = Anchor.center;

    rememberSelection ??= menu.entries.first;

    menu.preselectEntry(rememberSelection);
    menu.onPreselected = (it) => rememberSelection = it;

    softkeys('Back', null, (_) => popScreen());

    add(FlowText(
      text: '"Pixelating Game Screen" is a bit more retro, but does not play well with the "hi-res physics". Give it a try anyway!',
      font: tiny_font,
      insets: Vector2(6,6),
      position: Vector2(160, 159),
      size: Vector2(160, 40),
      anchor: Anchor.topLeft,
    ));
  }

  void _selected(OptionsMenuEntry it) {
    logInfo('Selected: $it');
    switch (it) {
      case OptionsMenuEntry.pixelate:
        visual.pixelate = !visual.pixelate;
      case OptionsMenuEntry.pixelate_screen:
        visual.pixelate_screen = !visual.pixelate_screen;
    }
    pixelate.checked = visual.pixelate;
    pixelate_screen.checked = visual.pixelate_screen;
  }
}
