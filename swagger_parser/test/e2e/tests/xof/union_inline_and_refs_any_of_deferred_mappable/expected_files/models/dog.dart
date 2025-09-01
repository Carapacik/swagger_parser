// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'dog.mapper.dart';

@MappableClass()
class Dog with DogMappable {
  const Dog({
    required this.barkSound,
  });
  final String barkSound;

  static Dog fromJson(Map<String, dynamic> json) =>
      DogMapper.ensureInitialized().decodeMap<Dog>(json);
}
