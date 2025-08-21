// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_item.freezed.dart';
part 'draft_item.g.dart';

@Freezed()
class DraftItem with _$DraftItem {
  const factory DraftItem({
    String? id,
    String? content,
    bool? isDraft,
  }) = _DraftItem;

  factory DraftItem.fromJson(Map<String, Object?> json) =>
      _$DraftItemFromJson(json);
}
