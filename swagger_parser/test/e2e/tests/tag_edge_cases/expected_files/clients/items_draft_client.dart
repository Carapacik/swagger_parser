// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/draft_item.dart';

part 'items_draft_client.g.dart';

@RestApi()
abstract class ItemsDraftClient {
  factory ItemsDraftClient(Dio dio, {String? baseUrl}) = _ItemsDraftClient;

  /// Get draft items
  @GET('/items/draft')
  Future<List<DraftItem>> getDraftItems();
}
