// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'default_error.freezed.dart';
part 'default_error.g.dart';

@Freezed()
class DefaultError with _$DefaultError {
  const factory DefaultError({
    String? message,
    int? code,
  }) = _DefaultError;

  factory DefaultError.fromJson(Map<String, Object?> json) =>
      _$DefaultErrorFromJson(json);
}
