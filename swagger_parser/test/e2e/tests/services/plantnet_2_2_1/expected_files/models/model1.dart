// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status.dart';

part 'model1.freezed.dart';
part 'model1.g.dart';

@Freezed()
class Model1 with _$Model1 {
  const factory Model1({
    Status? status,
  }) = _Model1;

  factory Model1.fromJson(Map<String, Object?> json) => _$Model1FromJson(json);
}
