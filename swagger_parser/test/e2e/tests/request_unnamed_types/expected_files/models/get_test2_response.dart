// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_test2_response.freezed.dart';
part 'get_test2_response.g.dart';

@Freezed()
class GetTest2Response with _$GetTest2Response {
  const factory GetTest2Response({
    required List<String> list,
    required String? name,
    String? lastname,
  }) = _GetTest2Response;

  factory GetTest2Response.fromJson(Map<String, Object?> json) =>
      _$GetTest2ResponseFromJson(json);
}
