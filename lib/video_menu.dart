import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../util/extensions.dart';
import 'components/basic_menu.dart';
import 'components/basic_menu_button.dart';
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
}

class VideoMenu extends GameScriptComponent with HasAutoDisposeShortcuts, KeyboardHandler, HasGameKeys {
  static OptionsMenuEntry? rememberSelection;

  late final BasicMenuButton pixelate;

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tinyFont, scale: 1);
    textXY('Video Mode', xCenter, 16, scale: 2);

    final buttonSheet = await sheetI('button_option.png', 1, 2);
    final menu = added(BasicMenu<OptionsMenuEntry>(buttonSheet, tinyFont, _selected));
    pixelate = menu.addEntry(OptionsMenuEntry.pixelate, 'Pixelate FX', anchor: Anchor.centerLeft);

    pixelate.checked = visual.pixelate;

    menu.position.setValues(xCenter, yCenter);
    menu.anchor = Anchor.center;

    rememberSelection ??= menu.entries.first;

    menu.preselectEntry(rememberSelection);
    menu.onPreselected = (it) => rememberSelection = it;

    softkeys('Back', null, (_) => popScreen());
  }

  void _selected(OptionsMenuEntry it) {
    logInfo('Selected: $it');
    switch (it) {
      case OptionsMenuEntry.pixelate:
        visual.pixelate = !visual.pixelate;
    }
    pixelate.checked = visual.pixelate;
  }
}
