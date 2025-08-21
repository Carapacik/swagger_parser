// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/credential_types.dart';
import '../models/enum_class.dart';
import '../models/enum_class_dynamic.dart';
import '../models/nullable_enum_in_object.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  /// [enumClass] - description.
  ///
  /// [enumClassDynamic] - description.
  ///
  /// [credentialTypes] - description.
  @GET('/api/v1/category/')
  Future<void> apiV1CategoryList({
    @Query('enum_class') required List<EnumClass?> enumClass,
    @Query('enum_class_dynamic')
    required List<EnumClassDynamic> enumClassDynamic,
    @Query('nullable_enum_in_object')
    required NullableEnumInObject nullableEnumInObject,
    @Query('credentialTypes')
    List<CredentialTypes>? credentialTypes = const [apple],
  });
}
