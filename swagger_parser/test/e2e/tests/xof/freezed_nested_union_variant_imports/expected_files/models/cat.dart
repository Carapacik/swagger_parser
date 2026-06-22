// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'cat_toy_union.dart';
import 'cat_type.dart';

part 'cat.freezed.dart';
part 'cat.g.dart';

/// A union variant that itself contains a nested discriminated union.
@Freezed()
abstract class Cat with _$Cat {
  const factory Cat({
    required CatType type,
    required CatToyUnion toy,
  }) = _Cat;

  factory Cat.fromJson(Map<String, Object?> json) => _$CatFromJson(json);
}
