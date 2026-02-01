// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'character.dart';

part 'user_character.freezed.dart';
part 'user_character.g.dart';

@Freezed()
class UserCharacter with _$UserCharacter {
  const factory UserCharacter({
    /// User character name
    required String name,

    /// Character level
    required int level,

    /// Character information
    required Character character,
  }) = _UserCharacter;

  factory UserCharacter.fromJson(Map<String, Object?> json) =>
      _$UserCharacterFromJson(json);
}
