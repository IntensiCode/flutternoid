enum ExtraId {
  laser,
  catcher,
  expander,
  disruptor,
  slow_down,
  multi_ball,
  extra_life,
  ;

  static ExtraId from(String name) => ExtraId.values.firstWhere((e) => e.name == name);
}
