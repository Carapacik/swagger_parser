// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum TaskStatus {
  @JsonValue('pending')
  pending('pending'),
  @JsonValue('in_progress')
  inProgress('in_progress'),
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('cancelled')
  cancelled('cancelled'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const TaskStatus(this.json);

  factory TaskStatus.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<TaskStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}

// Flutter compute serialization functions for TaskStatus
FutureOr<TaskStatus> deserializeTaskStatus(String json) =>
    TaskStatus.fromJson(json);

FutureOr<List<TaskStatus>> deserializeTaskStatusList(List<String> json) =>
    json.map((e) => TaskStatus.fromJson(e)).toList();

FutureOr<String?> serializeTaskStatus(TaskStatus? object) => object?.json;

FutureOr<List<String?>> serializeTaskStatusList(List<TaskStatus>? objects) =>
    objects?.map((e) => e.json).toList() ?? [];
