import 'package:flame/components.dart';

class VisualConfiguration {
  final frame_shadow_size = 6.0;
  final shadow_offset = 4.0;

  final brick_width = 12;
  final brick_height = 6;
  final brick_inset = 2.5; // offset from the frame walls

  final level_bricks = Vector2(15, 20);

  final game_offset = Vector2(16, 0); // offset into the screen - to show passing stars outside
  final border_size = 8.0; // frame border width
  late final game_position = game_offset + Vector2.all(border_size) + Vector2.all(2);

  late final game_frame_size = Vector2.all(200);
  late final game_pixels = Vector2(
    game_frame_size.x - border_size * 2 - brick_inset * 2,
    game_frame_size.y - border_size,
  );

  late final slow_down_area = game_pixels.y / 3;

  late final background_offset = Vector2.all(-border_size - brick_inset);
}
