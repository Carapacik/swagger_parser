// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'model5.dart';
import 'predicted_organs.dart';
import 'query.dart';
import 'result.dart';
import 'results.dart';

part 'identification_result.freezed.dart';
part 'identification_result.g.dart';

@Freezed()
class IdentificationResult with _$IdentificationResult {
  const factory IdentificationResult({
    Query? query,
    String? language,
    String? preferedReferential,
    String? switchToProject,
    String? bestMatch,
    Results? results,
    num? remainingIdentificationRequests,
    String? version,
    PredictedOrgans? predictedOrgans,
  }) = _IdentificationResult;

  factory IdentificationResult.fromJson(Map<String, Object?> json) =>
      _$IdentificationResultFromJson(json);
}
