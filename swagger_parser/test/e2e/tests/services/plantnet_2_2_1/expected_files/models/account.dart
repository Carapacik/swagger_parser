// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'name.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@Freezed()
class Account with _$Account {
  const factory Account({
    String? id,
    String? username,
    Name? name,
    String? created,
  }) = _Account;

  factory Account.fromJson(Map<String, Object?> json) =>
      _$AccountFromJson(json);
}
