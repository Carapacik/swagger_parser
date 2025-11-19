// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_whats_new_items_response.dart';

part 'whats_new_client.g.dart';

@RestApi()
abstract class WhatsNewClient {
  factory WhatsNewClient(Dio dio, {String? baseUrl}) = _WhatsNewClient;

  /// Get what's new items
  @GET('/whats-new/items')
  Future<List<GetWhatsNewItemsResponse>> getWhatsNewItems();
}
