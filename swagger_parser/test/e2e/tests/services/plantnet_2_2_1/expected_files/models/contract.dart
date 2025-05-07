// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract.freezed.dart';
part 'contract.g.dart';

@Freezed()
class Contract with _$Contract {
  const factory Contract({
    String? plan,
    String? status,
    String? firstSignatureDate,
    String? latestSignatureDate,
    String? nextSignatureDate,
    num? indicativeYearlyQuota,
    String? currency,
  }) = _Contract;

  factory Contract.fromJson(Map<String, Object?> json) =>
      _$ContractFromJson(json);
}
