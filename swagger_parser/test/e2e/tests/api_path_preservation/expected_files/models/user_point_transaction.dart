// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_point_transaction.freezed.dart';
part 'user_point_transaction.g.dart';

/// User point transaction record
@Freezed()
class UserPointTransaction with _$UserPointTransaction {
  const factory UserPointTransaction({
    /// Transaction ID
    required String id,

    /// Transaction amount (positive for earn, negative for spend)
    required int amount,

    /// Transaction timestamp
    @JsonKey(name: 'occurred_at') required DateTime occurredAt,

    /// Transaction description
    String? description,
  }) = _UserPointTransaction;

  factory UserPointTransaction.fromJson(Map<String, Object?> json) =>
      _$UserPointTransactionFromJson(json);
}
