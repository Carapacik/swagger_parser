// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'enum_class_dynamic.mapper.dart';

@MappableEnum(defaultValue: EnumClassDynamic.unknown)
enum EnumClassDynamic {
  /// The name has been replaced because it contains a keyword. Original name: `-index`.
  @MappableValue('-index')
  valueMinusIndex,

  @MappableValue('-name')
  minusName,

  /// The name has been replaced because it contains a keyword. Original name: `index`.
  @MappableValue('index')
  valueIndex,

  @MappableValue('name')
  name,

  /// The name has been replaced because it contains a keyword. Original name: `json`.
  @MappableValue('json')
  valueJson,

  @MappableValue('yaml')
  yaml,

  @MappableValue(-1)
  valueMinus1,

  @MappableValue(0)
  value0,

  @MappableValue(1)
  value1,

  @MappableValue('1itemOne')
  value1itemOne,

  @MappableValue('2ItemTwo')
  value2ItemTwo,

  @MappableValue('3item_three')
  value3itemThree,

  @MappableValue('4ITEM-FOUR')
  value4itemFour,

  /// Incorrect name has been replaced. Original name: `5иллегалчарактер`.
  @MappableValue('5иллегалчарактер')
  undefined0,

  @MappableValue('6 item six')
  value6ItemSix,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue().toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<EnumClassDynamic> get $valuesDefined =>
      values.where((value) => value != EnumClassDynamic.unknown).toList();
}
