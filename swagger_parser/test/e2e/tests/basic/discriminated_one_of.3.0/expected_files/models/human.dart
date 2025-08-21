// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'family_members_union.dart';
import 'human_type.dart';

part 'human.freezed.dart';
part 'human.g.dart';

@Freezed()
class Human with _$Human {
  const factory Human({
    required HumanType type,

    /// The job of the human.
    required String job,
  }) = _Human;

  factory Human.fromJson(Map<String, Object?> json) => _$HumanFromJson(json);
}
