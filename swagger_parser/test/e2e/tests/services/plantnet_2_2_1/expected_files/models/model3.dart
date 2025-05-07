// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'account.dart';
import 'billing.dart';
import 'contract.dart';
import 'history.dart';
import 'model2.dart';
import 'security.dart';

part 'model3.freezed.dart';
part 'model3.g.dart';

@Freezed()
class Model3 with _$Model3 {
  const factory Model3({
    Account? account,
    Contract? contract,
    History? history,
    Billing? billing,
    Security? security,
  }) = _Model3;

  factory Model3.fromJson(Map<String, Object?> json) => _$Model3FromJson(json);
}
