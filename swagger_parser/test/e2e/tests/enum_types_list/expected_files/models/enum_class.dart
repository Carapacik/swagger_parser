// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum EnumClass {
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
  @JsonValue(-1)
  valueMinus1(-1),
  @JsonValue(0)
  value0(0),
  @JsonValue(1)
  value1(1),
  @JsonValue('1itemOne')
  value1itemOne('1itemOne'),
  @JsonValue('2ItemTwo')
  value2ItemTwo('2ItemTwo'),
  @JsonValue('3item_three')
  value3itemThree('3item_three'),
  @JsonValue('4ITEM-FOUR')
  value4itemFour('4ITEM-FOUR'),

  /// Incorrect name has been replaced. Original name: `5иллегалчарактер`.
  @JsonValue('5иллегалчарактер')
  undefined0('5иллегалчарактер'),
  @JsonValue('6 item six')
  value6ItemSix('6 item six'),

  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @JsonValue(null)
  valueNull(null),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const EnumClass(this.json);

  factory EnumClass.fromJson(String? json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<EnumClass> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
