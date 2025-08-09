// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat.freezed.dart';
part 'cat.g.dart';

@Freezed()
class Cat with _$Cat {
  const factory Cat({
    bool? meows,
  }) = _Cat;

  factory Cat.fromJson(Map<String, Object?> json) => _$CatFromJson(json);
}
