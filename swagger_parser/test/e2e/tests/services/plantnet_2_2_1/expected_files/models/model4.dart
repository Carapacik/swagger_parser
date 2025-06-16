// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'common_names.dart';
import 'family.dart';
import 'genus.dart';

part 'model4.freezed.dart';
part 'model4.g.dart';

@Freezed()
class Model4 with _$Model4 {
  const factory Model4({
    String? scientificNameWithoutAuthor,
    String? scientificNameAuthorship,
    String? scientificName,
    Genus? genus,
    Family? family,
    CommonNames? commonNames,
  }) = _Model4;

  factory Model4.fromJson(Map<String, Object?> json) => _$Model4FromJson(json);
}
