// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_character.dart';

part 'get_api_v1_user_characters_response.freezed.dart';
part 'get_api_v1_user_characters_response.g.dart';

@Freezed()
class GetApiV1UserCharactersResponse with _$GetApiV1UserCharactersResponse {
  const factory GetApiV1UserCharactersResponse({
    required UserCharacter data,
  }) = _GetApiV1UserCharactersResponse;

  factory GetApiV1UserCharactersResponse.fromJson(Map<String, Object?> json) =>
      _$GetApiV1UserCharactersResponseFromJson(json);
}
