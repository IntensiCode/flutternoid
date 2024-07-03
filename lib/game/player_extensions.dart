import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../util/geom.dart';
import 'player.dart';

extension PlayerExtensions on Player {
  Vector2 relative_position(Vector2 it, {Vector2? out, Vector2? normalized}) {
    out ??= Vector2.zero();
    out.setFrom(it);
    out.sub(position);
    out.x += bat_width / 2;
    out.y += bat_height / 2;
    if (normalized != null) {
      normalized.setFrom(out);
      normalized.x /= bat_width;
      normalized.y /= bat_height;
    }
    return out;
  }

  double distance_and_closest(Vector2 it, [Vector2? out_closest]) {
    out_closest ??= Vector2.zero();
    out_closest.x = it.x.clamp(position.x - bat_width / 2, position.x + bat_width / 2);
    out_closest.y = it.y.clamp(position.y - bat_height / 2, position.y + bat_height / 2);
    return it.distanceTo(out_closest);
  }

  void bounce_vector_or_zero(Vector2 ball, double ball_radius, Vector2 out, Vector2 push) {
    logInfo('bat edge: $bat_edge');
    logInfo('hard edge: $hard_edge');

    push.setZero();

    final edge = bat_edge;

    if (_top_hit(ball, ball_radius, edge)) {
      out.setValues(0, -1);
      return;
    }

    if (hard_edge) {
      logInfo('player speed: $x_speed');
      if (_left_hit(ball, ball_radius, edge)) {
        final thrust = x_speed < 0 ? x_speed.abs() / 10 * 0.05 : 0;
        logInfo('thrust: $thrust');
        out.setValues(-1, -0.3 - thrust);
        push.x = x_speed;
      } else if (_right_hit(ball, ball_radius, edge)) {
        final thrust = x_speed > 0 ? x_speed.abs() / 10 * 0.05 : 0;
        logInfo('thrust: $thrust');
        out.setValues(1, -0.3 - thrust);
        push.x = x_speed;
      } else {
        out.setZero();
      }
      return;
    }

    if (_top_left_hit(ball, ball_radius, edge)) {
      out.setValues(-0.5, -1);
      push.x = x_speed;
    } else if (_top_right_hit(ball, ball_radius, edge)) {
      out.setValues(0.5, -1);
      push.x = x_speed;
    } else if (_bottom_left_hit(ball, ball_radius, edge)) {
      out.setValues(-1, 1);
      push.x = x_speed;
    } else if (_bottom_right_hit(ball, ball_radius, edge)) {
      out.setValues(1, 1);
      push.x = x_speed;
    } else {
      out.setZero();
    }
  }

  bool _top_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x - bat_width / 2 + edge,
        position.y - bat_height / 2,
        position.x + bat_width / 2 - edge,
        position.y - bat_height / 2,
      );

  bool _left_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x - bat_width / 2,
        position.y + bat_height / 2,
        position.x - bat_width / 2 + edge,
        position.y - bat_height / 2,
      );

  bool _right_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x + bat_width / 2,
        position.y + bat_height / 2,
        position.x + bat_width / 2 - edge,
        position.y - bat_height / 2,
      );

  bool _top_left_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x - bat_width / 2,
        position.y - 1,
        position.x - bat_width / 2 + edge,
        position.y - bat_height / 2,
      );

  bool _top_right_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x + bat_width / 2,
        position.y - 1,
        position.x + bat_width / 2 - edge,
        position.y - bat_height / 2,
      );

  bool _bottom_left_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x - bat_width / 2,
        position.y - 1,
        position.x - bat_width / 2 + edge,
        position.y + bat_height / 2,
      );

  bool _bottom_right_hit(Vector2 ball, double ball_radius, double edge) => circle_touches_line(
        ball,
        ball_radius,
        position.x + bat_width / 2,
        position.y - 1,
        position.x + bat_width / 2 - edge,
        position.y + bat_height / 2,
      );
}
