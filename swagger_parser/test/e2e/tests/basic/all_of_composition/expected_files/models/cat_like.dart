// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_like.freezed.dart';
part 'cat_like.g.dart';

/// Cat-like pet composed via allOf
@Freezed()
class CatLike with _$CatLike {
  const factory CatLike({
    int? id,
    bool? whiskers,
  }) = _CatLike;

  factory CatLike.fromJson(Map<String, Object?> json) =>
      _$CatLikeFromJson(json);
}
