// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'option.freezed.dart';
part 'option.g.dart';

@Freezed()
class Option with _$Option {
  const factory Option({
    @JsonKey(name: 'required_id') required int requiredId,
    @JsonKey(name: 'required_name') required String requiredName,
    @JsonKey(name: 'required_nullable_id') required int? requiredNullableId,
    @JsonKey(name: 'required_nullable_name')
    required String? requiredNullableName,
    @JsonKey(name: 'optional_id') int? optionalId,
    @JsonKey(name: 'optional_name') String? optionalName,
  }) = _Option;

  factory Option.fromJson(Map<String, Object?> json) => _$OptionFromJson(json);
}
