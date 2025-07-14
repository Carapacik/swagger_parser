// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'model5.freezed.dart';
part 'model5.g.dart';

@Freezed()
class Model5 with _$Model5 {
  const factory Model5({
    String? image,
    String? filename,
    String? organ,
    num? score,
  }) = _Model5;

  factory Model5.fromJson(Map<String, Object?> json) => _$Model5FromJson(json);
}
