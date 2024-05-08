// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/class_name1.dart';
import '../models/class_name2.dart';
import '../models/class_name3.dart';
import '../models/class_name5.dart';
import '../models/private_class_name4.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  @MultiPart()
  @GET('/api/v1/')
  Future<String> apiV1({
    @Part(name: 'p1') required ClassName1 p1,
    @Part(name: 'p2') required ClassName2 p2,
    @Part(name: 'p3') required ClassName3 p3,
    @Part(name: 'p4') required PrivateClassName4 p4,
    @Part(name: 'p5') required ClassName5 p5,
  });
}
