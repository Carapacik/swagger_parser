// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/class_name1_dto.dart';
import '../models/class_name2_dto.dart';
import '../models/class_name3_dto.dart';
import '../models/class_name56_dto.dart';
import '../models/class_name5_dto.dart';
import '../models/data1_att_dto.dart';
import '../models/data_att2_dto.dart';
import '../models/data_att4_dto.dart';
import '../models/enum0_dto.dart';
import '../models/object0_dto.dart';
import '../models/object1_dto.dart';
import '../models/private_att_data3_dto.dart';
import '../models/private_class_name4_dto.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// [p1Class] - Name not received and was auto-generated.
  ///
  /// [p2Enum] - Name not received and was auto-generated.
  @MultiPart()
  @GET('/api/v1/')
  Future<String> getApiV1({
    @Part(name: 'p1') required ClassName1Dto p1,
    @Part(name: 'p3') required ClassName3Dto p3,
    @Part(name: 'p5') required ClassName5Dto p5,
    @Part(name: 'v1') required Data1AttDto v1,
    @Part(name: 'v3') required PrivateAttData3Dto v3,
    @Part(name: 'p2') ClassName2Dto? p2,
    @Part(name: 'p4') PrivateClassName4Dto? p4,
    @Part(name: 'p6') ClassName56Dto? p6,
    @Part(name: 'v2') DataAtt2Dto? v2,
    @Part(name: 'v4') DataAtt4Dto? v4,
    @Part(name: 'p1_class') Object0Dto? p1Class,
    @Part(name: 'p2_enum') Enum0Dto? p2Enum,
  });

  /// [body] - Name not received and was auto-generated.
  @POST('/api/v1/')
  Future<String> postApiV1({
    @Body() Object1Dto? body,
  });
}
