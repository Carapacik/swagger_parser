// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'family1_members_sealed.dart';

part 'family1.mapper.dart';

@MappableClass()
class Family1 with Family1Mappable {
  const Family1({
    required this.members,
  });
  final List<Family1MembersSealed> members;

  static Family1 fromJson(Map<String, dynamic> json) =>
      Family1Mapper.ensureInitialized().decodeMap<Family1>(json);
}
