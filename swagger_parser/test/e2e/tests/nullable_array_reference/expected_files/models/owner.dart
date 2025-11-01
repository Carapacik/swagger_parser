// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'pet.dart';

part 'owner.freezed.dart';
part 'owner.g.dart';

@Freezed()
class Owner with _$Owner {
  const factory Owner({
    required String id,
    List<Pet>? pets,
  }) = _Owner;

  factory Owner.fromJson(Map<String, Object?> json) => _$OwnerFromJson(json);
}
