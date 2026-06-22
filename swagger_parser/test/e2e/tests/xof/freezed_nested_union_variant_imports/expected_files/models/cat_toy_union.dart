// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ball.dart';
import 'ball_kind.dart';
import 'mouse.dart';
import 'mouse_kind.dart';

part 'cat_toy_union.freezed.dart';
part 'cat_toy_union.g.dart';

@Freezed(unionKey: 'kind')
sealed class CatToyUnion with _$CatToyUnion {
  @FreezedUnionValue('Ball')
  const factory CatToyUnion.ball({
    required BallKind kind,
    required int diameterCm,
  }) = CatToyUnionBall;

  @FreezedUnionValue('Mouse')
  const factory CatToyUnion.mouse({
    required MouseKind kind,
    required bool squeaky,
  }) = CatToyUnionMouse;

  factory CatToyUnion.fromJson(Map<String, Object?> json) =>
      _$CatToyUnionFromJson(json);
}
