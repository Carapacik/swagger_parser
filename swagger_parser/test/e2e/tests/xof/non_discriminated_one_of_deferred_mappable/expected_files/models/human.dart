// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'human.mapper.dart';

@MappableClass()
class Human with HumanMappable {
  const Human({
    required this.job,
  });
  final String job;

  static Human fromJson(Map<String, dynamic> json) =>
      HumanMapper.ensureInitialized().decodeMap<Human>(json);
}
