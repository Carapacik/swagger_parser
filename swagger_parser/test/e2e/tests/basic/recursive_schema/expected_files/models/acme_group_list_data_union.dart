// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'acme_group.dart';
import 'acme_group_type.dart';
import 'basic_group.dart';
import 'basic_group_type.dart';

part 'acme_group_list_data_union.freezed.dart';
part 'acme_group_list_data_union.g.dart';

@Freezed(unionKey: 'type')
sealed class AcmeGroupListDataUnion with _$AcmeGroupListDataUnion {
  @FreezedUnionValue('ACME')
  const factory AcmeGroupListDataUnion.acme({
    required AcmeGroupType type,
    required String name,
    String? specialField,
  }) = AcmeGroupListDataUnionAcme;

  @FreezedUnionValue('BASIC')
  const factory AcmeGroupListDataUnion.basic({
    required BasicGroupType type,
    required String name,
  }) = AcmeGroupListDataUnionBasic;

  factory AcmeGroupListDataUnion.fromJson(Map<String, Object?> json) =>
      _$AcmeGroupListDataUnionFromJson(json);
}
