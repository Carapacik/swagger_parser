// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'image.dart';
import 'images.dart';
import 'organs.dart';

part 'query.freezed.dart';
part 'query.g.dart';

@Freezed()
class Query with _$Query {
  const factory Query({
    String? project,
    Images? images,
    Organs? organs,
    bool? includeRelatedImages,
    bool? noReject,
    String? type,
  }) = _Query;

  factory Query.fromJson(Map<String, Object?> json) => _$QueryFromJson(json);
}
