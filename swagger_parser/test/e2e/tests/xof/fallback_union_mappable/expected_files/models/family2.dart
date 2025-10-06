// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'family2_members_sealed.dart';

part 'family2.mapper.dart';

@MappableClass()
class Family2 with Family2Mappable {
  const Family2({
    required this.members,
  });
  final List<Family2MembersSealed> members;

  static Family2 fromJson(Map<String, dynamic> json) =>
      Family2Mapper.ensureInitialized().decodeMap<Family2>(json);
}
