// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@Freezed()
class Item with _$Item {
  const factory Item({
    @JsonKey(includeIfNull: false) String? id,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) String? version,
  }) = _Item;

  factory Item.fromJson(Map<String, Object?> json) => _$ItemFromJson(json);
}
