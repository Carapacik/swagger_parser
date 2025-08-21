// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required int integer1,
    required double float1,
    required double double1,
    required String string1,
    required num number1,
    required File string2,
    required DateTime string3,
    required String string4,
    required String string5,
    required File file1,
    required bool bool1,
    required dynamic object1,
    required List<String> array1,
    required List<List<List<String>>> array2,
  }) = _ClassName;

  factory ClassName.fromJson(Map<String, Object?> json) =>
      _$ClassNameFromJson(json);
}
