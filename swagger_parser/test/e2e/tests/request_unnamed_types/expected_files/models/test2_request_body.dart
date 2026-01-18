// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'example.dart';

part 'test2_request_body.freezed.dart';
part 'test2_request_body.g.dart';

@Freezed()
class Test2RequestBody with _$Test2RequestBody {
  const factory Test2RequestBody({
    required List<Example> list1,
    @JsonKey(includeIfNull: true) required String? name,
    @JsonKey(includeIfNull: false) List<Map<String, Example>>? list2,
    @JsonKey(includeIfNull: false) String? lastname,
  }) = _Test2RequestBody;

  factory Test2RequestBody.fromJson(Map<String, Object?> json) =>
      _$Test2RequestBodyFromJson(json);
}
