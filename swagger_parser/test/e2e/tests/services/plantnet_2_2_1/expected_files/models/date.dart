// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'date.freezed.dart';
part 'date.g.dart';

@Freezed()
class Date with _$Date {
  const factory Date({
    num? timestamp,
    String? string,
  }) = _Date;

  factory Date.fromJson(Map<String, Object?> json) => _$DateFromJson(json);
}
