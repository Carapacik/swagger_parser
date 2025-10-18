// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_nullable_date_time.dart';
import 'api_schedule.dart';

part 'pet.freezed.dart';
part 'pet.g.dart';

@Freezed()
abstract class Pet with _$Pet {
  const factory Pet({
    /// value in UTC, formatted in ISO String
    @JsonKey(includeIfNull: true) required DateTime? nullableDateTime,
    @JsonKey(includeIfNull: true)
    @Deprecated('This is marked as deprecated')
    required ApiNullableDateTime? nullableDateTimeRef,
    @JsonKey(includeIfNull: false) ApiSchedule? schedule,
  }) = _Pet;

  factory Pet.fromJson(Map<String, Object?> json) => _$PetFromJson(json);
}
