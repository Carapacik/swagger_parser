// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/debug_schema.dart';

part 'include_client.g.dart';

@RestApi()
abstract class IncludeClient {
  factory IncludeClient(Dio dio, {String? baseUrl}) = _IncludeClient;

  @GET('/api/v1/debug')
  Future<DebugSchema> getDebug();
}
