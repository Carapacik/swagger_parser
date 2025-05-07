// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'iucn.freezed.dart';
part 'iucn.g.dart';

@Freezed()
class Iucn with _$Iucn {
  const factory Iucn({
    required String id,
    required String category,
  }) = _Iucn;

  factory Iucn.fromJson(Map<String, Object?> json) => _$IucnFromJson(json);
}
