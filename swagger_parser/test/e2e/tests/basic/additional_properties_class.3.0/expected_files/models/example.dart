// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'example.freezed.dart';
part 'example.g.dart';

@Freezed()
class Example with _$Example {
  const factory Example({
    /// data
    required Map<String, dynamic> data,
  }) = _Example;

  factory Example.fromJson(Map<String, Object?> json) =>
      _$ExampleFromJson(json);
}
