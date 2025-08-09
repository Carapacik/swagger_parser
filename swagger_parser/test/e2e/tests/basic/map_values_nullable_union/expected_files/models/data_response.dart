// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_response.freezed.dart';
part 'data_response.g.dart';

@Freezed()
class DataResponse with _$DataResponse {
  const factory DataResponse({
    Map<String, String?>? data,
  }) = _DataResponse;

  factory DataResponse.fromJson(Map<String, Object?> json) =>
      _$DataResponseFromJson(json);
}
