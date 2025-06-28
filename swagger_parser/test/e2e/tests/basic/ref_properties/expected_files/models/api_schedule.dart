// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_schedule_detail.dart';

part 'api_schedule.freezed.dart';
part 'api_schedule.g.dart';

@Freezed()
abstract class ApiSchedule with _$ApiSchedule {
  const factory ApiSchedule({
    @JsonKey(includeIfNull: true, name: 'SUN') required ApiScheduleDetail? sun,
    @JsonKey(includeIfNull: true, name: 'MON') required ApiScheduleDetail? mon,
    @JsonKey(includeIfNull: true, name: 'TUE') required ApiScheduleDetail? tue,
    @JsonKey(includeIfNull: true, name: 'WED') required ApiScheduleDetail? wed,
    @JsonKey(includeIfNull: true, name: 'THU') required ApiScheduleDetail? thu,
    @JsonKey(includeIfNull: true, name: 'FRI') required ApiScheduleDetail? fri,
    @JsonKey(includeIfNull: true, name: 'SAT') required ApiScheduleDetail? sat,
  }) = _ApiSchedule;

  factory ApiSchedule.fromJson(Map<String, Object?> json) =>
      _$ApiScheduleFromJson(json);
}
