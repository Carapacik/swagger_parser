// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'address.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@Freezed()
class Item with _$Item {
  const factory Item({
    required List<File> images,
    Address? address,
  }) = _Item;

  factory Item.fromJson(Map<String, Object?> json) => _$ItemFromJson(json);
}
