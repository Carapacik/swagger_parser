// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_character_type.dart';

part 'character.freezed.dart';
part 'character.g.dart';

@Freezed()
class Character with _$Character {
  const factory Character({
    /// Unique name for URL
    required String urlName,

    /// Character name
    required String name,

    /// Character type
    required CharacterCharacterType characterType,
  }) = _Character;

  factory Character.fromJson(Map<String, Object?> json) =>
      _$CharacterFromJson(json);
}
