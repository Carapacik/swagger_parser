// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum Organs {
  @JsonValue('leaf')
  leaf('leaf'),
  @JsonValue('flower')
  flower('flower'),
  @JsonValue('fruit')
  fruit('fruit'),
  @JsonValue('bark')
  bark('bark'),
  @JsonValue('auto')
  auto('auto'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Organs(this.json);

  factory Organs.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
}
