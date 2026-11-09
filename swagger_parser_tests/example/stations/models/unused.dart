class Unused {
  const Unused(this.value);

  factory Unused.fromJson(Object? json) {
    return Unused(json as int);
  }

  final int value;

  Object? toJson() => value;
}
