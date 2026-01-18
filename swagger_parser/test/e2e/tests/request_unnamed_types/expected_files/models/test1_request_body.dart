// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'test1_request_body.freezed.dart';
part 'test1_request_body.g.dart';

@Freezed()
class Test1RequestBody with _$Test1RequestBody {
  const factory Test1RequestBody({
    required List<dynamic> list,
    @JsonKey(includeIfNull: true) required String? name,
    @JsonKey(includeIfNull: false) String? lastname,
  }) = _Test1RequestBody;

  factory Test1RequestBody.fromJson(Map<String, Object?> json) =>
      _$Test1RequestBodyFromJson(json);
}
