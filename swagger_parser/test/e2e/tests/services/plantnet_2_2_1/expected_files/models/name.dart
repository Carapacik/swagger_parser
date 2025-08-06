// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'name.freezed.dart';
part 'name.g.dart';

@Freezed()
class Name with _$Name {
  const factory Name({
    String? first,
    String? last,
  }) = _Name;

  factory Name.fromJson(Map<String, Object?> json) => _$NameFromJson(json);
}
