// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@Freezed()
abstract class ItemDto with _$ItemDto {
  const factory ItemDto({
    required String id,
  }) = _ItemDto;

  factory ItemDto.fromJson(Map<String, Object?> json) =>
      _$ItemDtoFromJson(json);
}
