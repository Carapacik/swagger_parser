// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_recurring_rule_dto.freezed.dart';
part 'update_recurring_rule_dto.g.dart';

@Freezed(fromJson: false, toJson: false)
class UpdateRecurringRuleDto with _$UpdateRecurringRuleDto {
  const UpdateRecurringRuleDto._();

  const factory UpdateRecurringRuleDto({
    required String frequency,
    @JsonKey(includeIfNull: false) int? interval,
    @Default(false) bool intervalPresent,
  }) = _UpdateRecurringRuleDto;

  factory UpdateRecurringRuleDto.fromJson(Map<String, Object?> json) {
    final data = _UpdateRecurringRuleDtoJson.fromJson(json);
    return UpdateRecurringRuleDto(
      frequency: data.frequency,
      interval: data.interval,
      intervalPresent: json.containsKey('interval'),
    );
  }

  Map<String, Object?> toJson() {
    final json = _UpdateRecurringRuleDtoJson(
      frequency: frequency,
      interval: interval,
    ).toJson();
    if (interval == null) {
      if (intervalPresent) {
        json['interval'] = null;
      } else {
        json.remove('interval');
      }
    }
    return json;
  }
}

@JsonSerializable()
class _UpdateRecurringRuleDtoJson {
  const _UpdateRecurringRuleDtoJson({
    required this.frequency,
    this.interval,
  });

  factory _UpdateRecurringRuleDtoJson.fromJson(Map<String, Object?> json) =>
      _$UpdateRecurringRuleDtoJsonFromJson(json);

  final String frequency;
  @JsonKey(includeIfNull: false)
  final int? interval;

  Map<String, Object?> toJson() => _$UpdateRecurringRuleDtoJsonToJson(this);
}
