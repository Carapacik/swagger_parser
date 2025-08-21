// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'anchor_reference.freezed.dart';
part 'anchor_reference.g.dart';

@Freezed()
class AnchorReference with _$AnchorReference {
  const factory AnchorReference({
    /// Shared field from anchor
    String? sharedField1,
    int? sharedField2,
  }) = _AnchorReference;

  factory AnchorReference.fromJson(Map<String, Object?> json) =>
      _$AnchorReferenceFromJson(json);
}
