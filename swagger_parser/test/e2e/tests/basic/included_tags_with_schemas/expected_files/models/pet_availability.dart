// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum PetAvailability {
  @JsonValue('IN_STOCK')
  inStock('IN_STOCK'),
  @JsonValue('OUT_OF_STOCK')
  outOfStock('OUT_OF_STOCK'),
  @JsonValue('RESERVED')
  reserved('RESERVED'),
  @JsonValue('SOLD')
  sold('SOLD'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const PetAvailability(this.json);

  factory PetAvailability.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<PetAvailability> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
