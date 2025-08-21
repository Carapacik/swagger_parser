// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'example.dart';

part 'example_parsable.freezed.dart';
part 'example_parsable.g.dart';

@Freezed()
class ExampleParsable with _$ExampleParsable {
  const factory ExampleParsable({
    /// data
    required Map<String, Example> data,
  }) = _ExampleParsable;

  factory ExampleParsable.fromJson(Map<String, Object?> json) =>
      _$ExampleParsableFromJson(json);
}
