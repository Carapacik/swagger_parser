// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/item.dart';

part 'items_2a3_client.g.dart';

@RestApi()
abstract class Items2a3Client {
  factory Items2a3Client(Dio dio, {String? baseUrl}) = _Items2a3Client;

  /// Get all items
  @GET('/items/list')
  Future<List<Item>> getItems();
}
