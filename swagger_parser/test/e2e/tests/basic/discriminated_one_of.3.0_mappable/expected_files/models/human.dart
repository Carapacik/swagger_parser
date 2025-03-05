// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dart_mappable/dart_mappable.dart';

import 'family_members_union.dart';
import 'human_type.dart';

part 'human.mapper.dart';

@MappableClass(discriminatorValue: 'Human')
class Human extends FamilyMembersUnion with HumanMappable {
  const Human({
    required this.type,
    required this.job,
  });
  final HumanType type;
  final String job;

  static Human fromJson(Map<String, dynamic> json) =>
      HumanMapper.ensureInitialized().decodeMap<Human>(json);
}
