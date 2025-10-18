// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'enum_class.freezed.dart';
part 'enum_class.g.dart';

@Freezed()
class EnumClass with _$EnumClass {
  const factory EnumClass({
    required String? p1,
    @JsonKey(name: 'p2_null') required List<String>? p2Null,
    @JsonKey(name: 'p2_null_all') required List<String?>? p2NullAll,
    @JsonKey(name: 'nested_collections')
    required List<List<Map<String, List<Map<String, int>?>>>?>
        nestedCollections,
  }) = _EnumClass;

  factory EnumClass.fromJson(Map<String, Object?> json) =>
      _$EnumClassFromJson(json);
}
