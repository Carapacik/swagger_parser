// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'above_quota.dart';
import 'count.dart';

part 'model2.freezed.dart';
part 'model2.g.dart';

@Freezed()
class Model2 with _$Model2 {
  const factory Model2({
    String? period,
    String? startDate,
    String? endDate,
    Count? count,
    AboveQuota? aboveQuota,
  }) = _Model2;

  factory Model2.fromJson(Map<String, Object?> json) => _$Model2FromJson(json);
}
