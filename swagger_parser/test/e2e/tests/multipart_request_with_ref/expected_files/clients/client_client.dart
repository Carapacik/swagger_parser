// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/item.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// create  item
  @MultiPart()
  @POST('/multipart/request/props')
  Future<String> postMultipartRequestProps({
    @Part(name: 'images') List<File>? images,
  });

  /// create  item
  @MultiPart()
  @POST('/multipart/request/ref')
  Future<String> postMultipartRequestRef({
    @Part() required Item file,
  });
}
