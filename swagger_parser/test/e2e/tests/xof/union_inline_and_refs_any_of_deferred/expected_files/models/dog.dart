// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dog.freezed.dart';
part 'dog.g.dart';

@Freezed()
class Dog with _$Dog {
  const factory Dog({
    /// The sound of the dog's bark.
    required String barkSound,
  }) = _Dog;

  factory Dog.fromJson(Map<String, Object?> json) => _$DogFromJson(json);
}
