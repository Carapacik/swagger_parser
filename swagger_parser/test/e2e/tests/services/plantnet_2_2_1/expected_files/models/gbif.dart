// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'gbif.freezed.dart';
part 'gbif.g.dart';

@Freezed()
class Gbif with _$Gbif {
  const factory Gbif({
    required num id,
  }) = _Gbif;

  factory Gbif.fromJson(Map<String, Object?> json) => _$GbifFromJson(json);
}
