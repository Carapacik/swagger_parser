// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/enum_class.dart';
import '../models/enum_class_dynamic.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  /// [enumClass] - description.
  ///
  /// [enumClassDynamic] - description.
  @GET('/api/v1/category/')
  Future<void> apiV1CategoryList({
    @Query('enum_class') required List<EnumClass> enumClass,
    @Query('enum_class_dynamic')
    required List<EnumClassDynamic> enumClassDynamic,
  });
}
