// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'family_members_union.g.dart';

@JsonSerializable()
class FamilyMembersUnion {
  const FamilyMembersUnion(this.data);

  /// Raw JSON data for union type.
  /// This can be one of: Cat, Dog, Human
  /// Use try-catch or manual inspection to determine the actual type.
  final Map<String, dynamic> data;

  factory FamilyMembersUnion.fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnion(json);

  Map<String, dynamic> toJson() => data;
}
