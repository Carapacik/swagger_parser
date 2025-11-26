// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// pet status in the store
@JsonEnum()
enum PetStatus {
  @JsonValue('available')
  available('available'),
  @JsonValue('pending')
  pending('pending'),
  @JsonValue('sold')
  sold('sold'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const PetStatus(this.json);

  factory PetStatus.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<PetStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
