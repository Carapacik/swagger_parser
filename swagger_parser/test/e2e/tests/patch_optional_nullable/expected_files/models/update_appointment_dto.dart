// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'update_recurring_rule_dto.dart';

part 'update_appointment_dto.freezed.dart';
part 'update_appointment_dto.g.dart';

@Freezed(fromJson: false, toJson: false)
class UpdateAppointmentDto with _$UpdateAppointmentDto {
  const UpdateAppointmentDto._();

  const factory UpdateAppointmentDto({
    @Default(false) bool reminderEnabled,
    @JsonKey(includeIfNull: false) UpdateRecurringRuleDto? recurringRuleData,
    @Default(false) bool recurringRuleDataPresent,
    @JsonKey(includeIfNull: false) String? notes,
    @Default(false) bool notesPresent,
  }) = _UpdateAppointmentDto;

  factory UpdateAppointmentDto.fromJson(Map<String, Object?> json) {
    final data = _UpdateAppointmentDtoJson.fromJson(json);
    return UpdateAppointmentDto(
      reminderEnabled: data.reminderEnabled,
      recurringRuleData: data.recurringRuleData,
      recurringRuleDataPresent: json.containsKey('recurringRuleData'),
      notes: data.notes,
      notesPresent: json.containsKey('notes'),
    );
  }

  Map<String, Object?> toJson() {
    final json = _UpdateAppointmentDtoJson(
      reminderEnabled: reminderEnabled,
      recurringRuleData: recurringRuleData,
      notes: notes,
    ).toJson();
    if (recurringRuleData == null) {
      if (recurringRuleDataPresent) {
        json['recurringRuleData'] = null;
      } else {
        json.remove('recurringRuleData');
      }
    }
    if (notes == null) {
      if (notesPresent) {
        json['notes'] = null;
      } else {
        json.remove('notes');
      }
    }
    return json;
  }
}

@JsonSerializable()
class _UpdateAppointmentDtoJson {
  const _UpdateAppointmentDtoJson({
    this.reminderEnabled = false,
    this.recurringRuleData,
    this.notes,
  });

  factory _UpdateAppointmentDtoJson.fromJson(Map<String, Object?> json) =>
      _$UpdateAppointmentDtoJsonFromJson(json);

  final bool reminderEnabled;
  @JsonKey(includeIfNull: false)
  final UpdateRecurringRuleDto? recurringRuleData;
  @JsonKey(includeIfNull: false)
  final String? notes;

  Map<String, Object?> toJson() => _$UpdateAppointmentDtoJsonToJson(this);
}
