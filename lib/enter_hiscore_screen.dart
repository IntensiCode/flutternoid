import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'game/game_state.dart' as gs;
import 'game/game_state.dart';
import 'game/hiscore.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

class EnterHiscoreScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font);
    textXY('You made it into the', xCenter, lineHeight * 2);
    textXY('HISCORE', xCenter, lineHeight * 3, scale: 2);

    textXY('Score', xCenter, lineHeight * 5);
    textXY('${gs.state.score}', xCenter, lineHeight * 6, scale: 2);

    textXY('Round', xCenter, lineHeight * 8);
    textXY('${gs.state.level_number_starting_at_1}', xCenter, lineHeight * 9, scale: 2);

    textXY('Enter your name:', xCenter, lineHeight * 12);

    var input = textXY('_', xCenter, lineHeight * 13, scale: 2);

    textXY('Press enter to confirm', xCenter, lineHeight * 16);

    shortcuts.snoop = (it) {
      if (it.length == 1) {
        name += it;
      } else if (it == '<Space>' && name.isNotEmpty) {
        name += ' ';
      } else if (it == '<Backspace>' && name.isNotEmpty) {
        name = name.substring(0, name.length - 1);
      } else if (it == '<Enter>' && name.isNotEmpty) {
        shortcuts.snoop = (_) {};
        hiscore.insert(gs.state.score, gs.state.level_number_starting_at_1, name);
        showScreen(Screen.hiscore);
        clear_game_state();
      }
      if (name.length > 10) name = name.substring(0, 10);

      input.removeFromParent();
      input = textXY('${name}_', xCenter, lineHeight * 13, scale: 2);
    };
  }

  Future clear_game_state() async {
    await state.delete();
    state.reset();
  }

  String name = '';
}
