// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_data.freezed.dart';
part 'audit_data.g.dart';

@Freezed()
class AuditData with _$AuditData {
  const factory AuditData({
    /// Last modified timestamp from anchor
    required DateTime lastModified,

    /// User who modified from anchor
    @JsonKey(includeIfNull: false) String? modifiedBy,
  }) = _AuditData;

  factory AuditData.fromJson(Map<String, Object?> json) =>
      _$AuditDataFromJson(json);
}
