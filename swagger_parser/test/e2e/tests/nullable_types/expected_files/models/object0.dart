// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'object0.freezed.dart';
part 'object0.g.dart';

@Freezed()
class Object0 with _$Object0 {
  const factory Object0({
    required String? p1,
    @JsonKey(name: 'p2_null') required List<String>? p2Null,
    @JsonKey(name: 'p2_null_all') required List<String?>? p2NullAll,
    @JsonKey(name: 'nested_collections')
    required List<List<Map<String, List<Map<String, int>?>>>?>
        nestedCollections,
  }) = _Object0;

  factory Object0.fromJson(Map<String, Object?> json) =>
      _$Object0FromJson(json);
}
