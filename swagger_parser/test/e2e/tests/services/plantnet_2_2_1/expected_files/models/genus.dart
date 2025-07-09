// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'genus.freezed.dart';
part 'genus.g.dart';

@Freezed()
class Genus with _$Genus {
  const factory Genus({
    String? scientificNameWithoutAuthor,
    String? scientificNameAuthorship,
    String? scientificName,
  }) = _Genus;

  factory Genus.fromJson(Map<String, Object?> json) => _$GenusFromJson(json);
}
