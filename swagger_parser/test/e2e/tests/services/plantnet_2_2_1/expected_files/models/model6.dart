// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'count.dart';
import 'remaining.dart';

part 'model6.freezed.dart';
part 'model6.g.dart';

@Freezed()
class Model6 with _$Model6 {
  const factory Model6({
    String? day,
    Count? count,
    Remaining? remaining,
  }) = _Model6;

  factory Model6.fromJson(Map<String, Object?> json) => _$Model6FromJson(json);
}
