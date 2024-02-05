// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/object0.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// Test.
  /// 
  /// Test.
  /// 
  /// [files] - Sample List of Files.
  /// 
  /// [address] - Sample Address.
  /// Name not received and was auto-generated.
  /// 
  /// [image] - Sample Image.
  @MultiPart()
  @GET('/test-multipart')
  Future<void> testMultipart({
    @Part(name: 'files') required List<File> files,
    @Part(name: 'address') Object0? address,
    @Part(name: 'image') File? image,
  });
}
