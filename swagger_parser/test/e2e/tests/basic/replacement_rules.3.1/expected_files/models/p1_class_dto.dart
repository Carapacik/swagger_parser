// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'p1_class_dto.freezed.dart';
part 'p1_class_dto.g.dart';

@Freezed()
class P1ClassDto with _$P1ClassDto {
  const factory P1ClassDto({
    required DateTime test,
  }) = _P1ClassDto;

  factory P1ClassDto.fromJson(Map<String, Object?> json) =>
      _$P1ClassDtoFromJson(json);
}
