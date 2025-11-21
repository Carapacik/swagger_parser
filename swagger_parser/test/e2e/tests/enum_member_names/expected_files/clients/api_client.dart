// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/enum_class.dart';
import '../models/x_enum_names.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  /// [enumClass] - description.
  ///
  /// [xEnumNames] - x-enumNames test.
  @GET('/api/v1/category/')
  Future<void> apiV1CategoryList({
    @Query('enum_class') required List<EnumClass> enumClass,
    @Query('xEnumNames') required XEnumNames xEnumNames,
  });
}
