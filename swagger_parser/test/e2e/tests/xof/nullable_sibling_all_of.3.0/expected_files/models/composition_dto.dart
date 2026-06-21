// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'item_dto.dart';

part 'composition_dto.freezed.dart';
part 'composition_dto.g.dart';

@Freezed()
abstract class CompositionDto with _$CompositionDto {
  const factory CompositionDto({
    /// OpenAPI 3.0 style: sibling nullable:true next to a single-element allOf
    required ItemDto? nullableAllOf,

    /// OpenAPI 3.1 style: oneOf with an explicit null branch (already supported)
    required ItemDto? nullableOneOf,
  }) = _CompositionDto;

  factory CompositionDto.fromJson(Map<String, Object?> json) =>
      _$CompositionDtoFromJson(json);
}
