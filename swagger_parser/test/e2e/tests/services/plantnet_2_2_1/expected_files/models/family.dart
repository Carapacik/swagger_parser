// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'family.freezed.dart';
part 'family.g.dart';

@Freezed()
class Family with _$Family {
  const factory Family({
    String? scientificNameWithoutAuthor,
    String? scientificNameAuthorship,
    String? scientificName,
  }) = _Family;

  factory Family.fromJson(Map<String, Object?> json) => _$FamilyFromJson(json);
}
