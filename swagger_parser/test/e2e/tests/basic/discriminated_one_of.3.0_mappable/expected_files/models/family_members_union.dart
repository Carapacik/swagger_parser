// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';
import 'human.dart';
import 'human_type.dart';

part 'family_members_union.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [Cat, Dog, Human])
class FamilyMembersUnion with FamilyMembersUnionMappable {
  const FamilyMembersUnion();

  T when<T>({
    required T Function(Cat cat) cat,
    required T Function(Dog dog) dog,
    required T Function(Human human) human,
  }) {
    return maybeWhen(
      cat: cat,
      dog: dog,
      human: human,
    )!;
  }

  T? maybeWhen<T>({
    T Function(Cat cat)? cat,
    T Function(Dog dog)? dog,
    T Function(Human human)? human,
  }) {
    return switch (this) {
      Cat _ => cat?.call(this as Cat),
      Dog _ => dog?.call(this as Dog),
      Human _ => human?.call(this as Human),
      _ => throw Exception("Unhandled type: ${this.runtimeType}"),
    };
  }

  static FamilyMembersUnion fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnion>(json);
}
