// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum Order {
  /// The name has been replaced because it contains a keyword. Original name: `-index`.
  @JsonValue('-index')
  valueMinusIndex('-index'),

  @JsonValue('-name')
  minusName('-name'),

  /// The name has been replaced because it contains a keyword. Original name: `index`.
  @JsonValue('index')
  valueIndex('index'),

  @JsonValue('name')
  name('name'),

  /// The name has been replaced because it contains a keyword. Original name: `json`.
  @JsonValue('json')
  valueJson('json'),

  @JsonValue('yaml')
  yaml('yaml'),

  @JsonValue('-5')
  valueMinus5('-5'),

  @JsonValue('15')
  value15('15'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Order(this.json);

  factory Order.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
}
