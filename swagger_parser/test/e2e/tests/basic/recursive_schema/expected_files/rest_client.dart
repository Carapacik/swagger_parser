// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/nodes_client.dart';
import 'clients/groups_client.dart';

/// API with Recursive Schemas `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  NodesClient? _nodes;
  GroupsClient? _groups;

  NodesClient get nodes => _nodes ??= NodesClient(_dio, baseUrl: _baseUrl);

  GroupsClient get groups => _groups ??= GroupsClient(_dio, baseUrl: _baseUrl);
}
