// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_point_balance.freezed.dart';
part 'user_point_balance.g.dart';

/// User point balance response
@Freezed()
class UserPointBalance with _$UserPointBalance {
  const factory UserPointBalance({
    /// Current point balance
    required int balance,
  }) = _UserPointBalance;

  factory UserPointBalance.fromJson(Map<String, Object?> json) =>
      _$UserPointBalanceFromJson(json);
}
