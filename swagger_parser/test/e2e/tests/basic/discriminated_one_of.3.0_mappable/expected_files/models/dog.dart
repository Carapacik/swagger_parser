// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'dog_type.dart';
import 'family_members_union.dart';

part 'dog.mapper.dart';

@MappableClass(discriminatorValue: 'Dog')
class Dog extends FamilyMembersUnion with DogMappable {
  const Dog({
    required this.type,
    required this.barkSound,
  });
  final DogType type;
  final String barkSound;

  static Dog fromJson(Map<String, dynamic> json) =>
      DogMapper.ensureInitialized().decodeMap<Dog>(json);
}
