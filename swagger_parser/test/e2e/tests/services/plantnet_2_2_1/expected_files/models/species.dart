// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'common_names.dart';

part 'species.freezed.dart';
part 'species.g.dart';

@Freezed()
class Species with _$Species {
  const factory Species({
    String? id,
    String? scientificNameWithoutAuthor,
    String? scientificNameAuthorship,
    num? gbifId,
    String? powoId,
    String? iucnCategory,
    CommonNames? commonNames,
  }) = _Species;

  factory Species.fromJson(Map<String, Object?> json) =>
      _$SpeciesFromJson(json);
}
