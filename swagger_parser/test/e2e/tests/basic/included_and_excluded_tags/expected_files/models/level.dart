// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum Level {
  @JsonValue('LOW')
  low('LOW'),
  @JsonValue('MEDIUM')
  medium('MEDIUM'),
  @JsonValue('HIGH')
  high('HIGH'),
  @JsonValue('CRITICAL')
  critical('CRITICAL'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Level(this.json);

  factory Level.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Level> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
