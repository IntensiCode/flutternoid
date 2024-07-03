enum BrickId {
  blue1('B1', strength: 1, score_per_hit: 1),
  green1('G1', strength: 1, score_per_hit: 1),
  orange1('O1', strength: 1, score_per_hit: 1),
  gray1('G1', strength: 1, score_per_hit: 1),
  red1('R1', strength: 1, score_per_hit: 1),
  blue2('B2', strength: 2, score_per_hit: 2),
  green2('G2', strength: 2, score_per_hit: 2),
  orange2('O2', strength: 2, score_per_hit: 2),
  gray2('G2', strength: 2, score_per_hit: 2),
  red2('R2', strength: 2, score_per_hit: 2),
  double('DD', strength: 6, score_per_hit: 3),
  green3('G3', strength: 3, score_per_hit: 3),
  orange3('O3', strength: 3, score_per_hit: 3),
  gray3('G3', strength: 3, score_per_hit: 3),
  massive('MM', strength: 0, score_per_hit: 0),
  ;

  final String id;
  final int strength;
  final int score_per_hit;

  const BrickId(this.id, {required this.strength, required this.score_per_hit});

  static BrickId from(String name) => BrickId.values.firstWhere((e) => e.name == name);

  static BrickId from_id(String id) => BrickId.values.firstWhere((e) => e.id == id);
}
