// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'task_status.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

@Freezed()
class TaskDto with _$TaskDto {
  const factory TaskDto({
    required int id,
    required String title,
    required bool completed,
    required TaskStatus status,
  }) = _TaskDto;

  factory TaskDto.fromJson(Map<String, Object?> json) =>
      _$TaskDtoFromJson(json);
}

// Flutter compute serialization functions for TaskDto
TaskDto deserializeTaskDto(Map<String, dynamic> json) => TaskDto.fromJson(json);

List<TaskDto> deserializeTaskDtoList(List<Map<String, dynamic>> json) =>
    json.map((e) => TaskDto.fromJson(e)).toList();

Map<String, dynamic> serializeTaskDto(TaskDto object) => object.toJson();

List<Map<String, dynamic>> serializeTaskDtoList(List<TaskDto> objects) =>
    objects.map((e) => e.toJson()).toList();
