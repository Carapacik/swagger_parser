// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'gbif.dart';
import 'image.dart';
import 'images.dart';
import 'iucn.dart';
import 'model4.dart';
import 'powo.dart';

part 'result.freezed.dart';
part 'result.g.dart';

@Freezed()
class Result with _$Result {
  const factory Result({
    num? score,
    Model4? species,
    Images? images,
    Gbif? gbif,
    Powo? powo,
    Iucn? iucn,
  }) = _Result;

  factory Result.fromJson(Map<String, Object?> json) => _$ResultFromJson(json);
}
