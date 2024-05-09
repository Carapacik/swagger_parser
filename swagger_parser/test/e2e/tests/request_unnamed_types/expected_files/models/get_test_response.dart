// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_test_response.freezed.dart';
part 'get_test_response.g.dart';

@Freezed()
class GetTestResponse with _$GetTestResponse {
  const factory GetTestResponse({
    required List<String> list,
    required String? name,
    required String lastname,
  }) = _GetTestResponse;

  factory GetTestResponse.fromJson(Map<String, Object?> json) =>
      _$GetTestResponseFromJson(json);
}
