// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_schedule_detail.freezed.dart';
part 'api_schedule_detail.g.dart';

@Freezed()
abstract class ApiScheduleDetail with _$ApiScheduleDetail {
  const factory ApiScheduleDetail({
    required String startTime,
    required String endTime,
  }) = _ApiScheduleDetail;

  factory ApiScheduleDetail.fromJson(Map<String, Object?> json) =>
      _$ApiScheduleDetailFromJson(json);
}
