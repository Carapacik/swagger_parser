// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'acme_group_type.dart';

part 'acme_group.freezed.dart';
part 'acme_group.g.dart';

@Freezed()
class AcmeGroup with _$AcmeGroup {
  const factory AcmeGroup({
    required AcmeGroupType type,
    required String name,
    String? specialField,
  }) = _AcmeGroup;

  factory AcmeGroup.fromJson(Map<String, Object?> json) =>
      _$AcmeGroupFromJson(json);
}
