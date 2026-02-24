// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'acme_group_list_data_union.dart';

part 'acme_group_list.freezed.dart';
part 'acme_group_list.g.dart';

@Freezed()
class AcmeGroupList with _$AcmeGroupList {
  const factory AcmeGroupList({
    required List<AcmeGroupListDataUnion> data,
  }) = _AcmeGroupList;

  factory AcmeGroupList.fromJson(Map<String, Object?> json) =>
      _$AcmeGroupListFromJson(json);
}
