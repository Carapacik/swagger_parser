// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/object0.dart';
import '../models/object1.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// create  item.
  ///
  /// [address] - Name not received and was auto-generated.
  @MultiPart()
  @POST('/multipart/request/props')
  Future<String> postMultipartRequestProps({
    @Part(name: 'images') required List<File> images,
    @Part(name: 'address') Object0? address,
  });

  /// create  item.
  ///
  /// [address] - Name not received and was auto-generated.
  @MultiPart()
  @POST('/multipart/request/ref')
  Future<String> postMultipartRequestRef({
    @Part(name: 'images') required List<File> images,
    @Part(name: 'address') Object1? address,
  });
}
