// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'family_members_sealed.dart';

part 'family.g.dart';

@JsonSerializable()
class Family {
  const Family({
    required this.members,
  });

  factory Family.fromJson(Map<String, Object?> json) => _$FamilyFromJson(json);

  final List<FamilyMembersSealed> members;

  Map<String, Object?> toJson() => _$FamilyToJson(this);
}
