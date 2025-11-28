// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// parsing mode
@JsonEnum()
enum XEnumNames {
  /// The name has been replaced because it contains a keyword. Original name: `default`.
  @JsonValue(0)
  valueDefault(0),
  @JsonValue(1)
  strict(1),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const XEnumNames(this.json);

  factory XEnumNames.fromJson(num json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final num? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<XEnumNames> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
