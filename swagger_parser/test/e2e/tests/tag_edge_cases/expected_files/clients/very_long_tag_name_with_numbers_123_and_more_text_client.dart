// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/long_tag_response.dart';

part 'very_long_tag_name_with_numbers_123_and_more_text_client.g.dart';

@RestApi()
abstract class VeryLongTagNameWithNumbers123AndMoreTextClient {
  factory VeryLongTagNameWithNumbers123AndMoreTextClient(Dio dio,
      {String? baseUrl}) = _VeryLongTagNameWithNumbers123AndMoreTextClient;

  /// Operation with very long tag
  @GET('/very/long/path')
  Future<LongTagResponse> getLongTagData();
}
