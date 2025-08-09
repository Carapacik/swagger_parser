// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'items_response.freezed.dart';
part 'items_response.g.dart';

@Freezed()
class ItemsResponse with _$ItemsResponse {
  const factory ItemsResponse({
    List<String?>? items,
  }) = _ItemsResponse;

  factory ItemsResponse.fromJson(Map<String, Object?> json) =>
      _$ItemsResponseFromJson(json);
}
