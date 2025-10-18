// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'p3_one_of.freezed.dart';
part 'p3_one_of.g.dart';

@Freezed()
class P3OneOf with _$P3OneOf {
  const factory P3OneOf({
    required String? p1,
    required List<String?>? p2,
  }) = _P3OneOf;

  factory P3OneOf.fromJson(Map<String, Object?> json) =>
      _$P3OneOfFromJson(json);
}
