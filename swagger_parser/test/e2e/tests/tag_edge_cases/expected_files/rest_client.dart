// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/items_2a3_version_4b5_client.dart';
import 'clients/items_draft_client.dart';
import 'clients/very_long_tag_name_with_numbers_123_and_more_text_client.dart';

/// Tag Edge Cases Test API `v1.0.0`.
///
/// Test API to verify various tag naming edge cases.
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  Items2a3Version4b5Client? _items2a3Version4b5;
  ItemsDraftClient? _itemsDraft;
  VeryLongTagNameWithNumbers123AndMoreTextClient?
      _veryLongTagNameWithNumbers123AndMoreText;

  Items2a3Version4b5Client get items2a3Version4b5 =>
      _items2a3Version4b5 ??= Items2a3Version4b5Client(_dio, baseUrl: _baseUrl);

  ItemsDraftClient get itemsDraft =>
      _itemsDraft ??= ItemsDraftClient(_dio, baseUrl: _baseUrl);

  VeryLongTagNameWithNumbers123AndMoreTextClient
      get veryLongTagNameWithNumbers123AndMoreText =>
          _veryLongTagNameWithNumbers123AndMoreText ??=
              VeryLongTagNameWithNumbers123AndMoreTextClient(_dio,
                  baseUrl: _baseUrl);
}
