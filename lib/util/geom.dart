import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

final _result = Vector2.zero();
final _bounce = Vector2.zero();
final _start = Vector2.zero();
final _end = Vector2.zero();
final _heading = Vector2.zero();

Vector2 bounce(Vector2 in_and_out, Vector2 normal) {
  _result.setFrom(in_and_out);
  final speed = _result.normalize();
  _bounce.setFrom(normal);
  final dot = normal.dot(_result);
  _bounce.scale(dot * 2);
  _result.sub(_bounce);
  if (dot > 0) logInfo('dot positive -> push');
  if (dot < 0) logInfo('dot negative -> bounce');
  if (dot == 0) logInfo('OH NO');
  _result.normalize();
  _result.scale(speed);
  in_and_out.setFrom(_result);
  return in_and_out;
}

bool circle_touches_line(
  Vector2 center,
  double radius,
  double line_start_x,
  double line_start_y,
  double line_end_x,
  double line_end_y,
) {
  _start.setValues(line_start_x, line_start_y);
  _end.setValues(line_end_x, line_end_y);
  final closest = closest_on_line(_start, _end, center);
  final distance = closest.distanceTo(center);
  return distance <= radius;
}

Vector2 closest_on_line(Vector2 start, Vector2 end, Vector2 point) {
  _heading.setFrom(end);
  _heading.sub(start);

  final max_rel_pos = _heading.normalize();

  _result.setFrom(point);
  _result.sub(start);

  final dot = _result.dot(_heading);
  final relative = dot.clamp(0.0, max_rel_pos);

  _result.setFrom(_heading);
  _result.scale(relative);
  _result.add(start);
  return _result;
}
