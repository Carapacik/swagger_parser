// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'cat.dart';
import 'cat_toy_union.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';

part 'get_pets_response_union.freezed.dart';
part 'get_pets_response_union.g.dart';

@Freezed(unionKey: 'type')
sealed class GetPetsResponseUnion with _$GetPetsResponseUnion {
  @FreezedUnionValue('Cat')
  const factory GetPetsResponseUnion.cat({
    required CatType type,
    required CatToyUnion toy,
  }) = GetPetsResponseUnionCat;

  @FreezedUnionValue('Dog')
  const factory GetPetsResponseUnion.dog({
    required DogType type,
    required String barkSound,
  }) = GetPetsResponseUnionDog;

  factory GetPetsResponseUnion.fromJson(Map<String, Object?> json) =>
      _$GetPetsResponseUnionFromJson(json);
}
