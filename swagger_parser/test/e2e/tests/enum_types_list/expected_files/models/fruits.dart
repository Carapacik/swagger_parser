// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum Fruits {
  @JsonValue('apple')
  apple('apple'),
  @JsonValue('orange')
  orange('orange'),

  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @JsonValue(null)
  valueNull(null),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Fruits(this.json);

  factory Fruits.fromJson(String? json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
}
