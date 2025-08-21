// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_dto.dart';

part 'paginated_user_dto.freezed.dart';
part 'paginated_user_dto.g.dart';

@Freezed()
class PaginatedUserDto with _$PaginatedUserDto {
  const factory PaginatedUserDto({
    required String? nextCursor,
    required String? previousCursor,
    required List<UserDto> data,
  }) = _PaginatedUserDto;

  factory PaginatedUserDto.fromJson(Map<String, Object?> json) =>
      _$PaginatedUserDtoFromJson(json);
}
