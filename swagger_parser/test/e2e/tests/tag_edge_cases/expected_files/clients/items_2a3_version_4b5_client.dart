// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/item.dart';

part 'items_2a3_version_4b5_client.g.dart';

@RestApi()
abstract class Items2a3Version4b5Client {
  factory Items2a3Version4b5Client(Dio dio, {String? baseUrl}) =
      _Items2a3Version4b5Client;

  /// Get items with multiple version markers
  @GET('/items/multi-version')
  Future<List<Item>> getMultiVersionItems();
}
