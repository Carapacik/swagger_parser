// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status_status.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    /// Status values that need to be considered for filter
    required List<StatusStatus> status,
  }) = _ClassName;

  factory ClassName.fromJson(Map<String, Object?> json) =>
      _$ClassNameFromJson(json);
}
