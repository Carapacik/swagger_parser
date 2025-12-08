// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:retrofit/retrofit.dart';

import '../models/task_dto.dart';

part 'task_client.g.dart';

@RestApi(parser: Parser.FlutterCompute)
abstract class TaskClient {
  factory TaskClient(Dio dio, {String? baseUrl}) = _TaskClient;

  @GET('/tasks')
  Future<List<TaskDto>> getTasks();

  @POST('/tasks')
  Future<TaskDto> createTask({
    @Body() TaskDto? body,
  });

  @GET('/tasks/{id}')
  Future<TaskDto> getTask({
    @Path('id') required int id,
  });
}
