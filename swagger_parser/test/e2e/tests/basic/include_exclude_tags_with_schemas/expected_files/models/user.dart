// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_profile.dart';
import 'user_role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed()
class User with _$User {
  const factory User({
    @JsonKey(includeIfNull: false) int? id,
    @JsonKey(includeIfNull: false) String? email,
    @JsonKey(includeIfNull: false) UserRole? role,
    @JsonKey(includeIfNull: false) UserProfile? profile,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
