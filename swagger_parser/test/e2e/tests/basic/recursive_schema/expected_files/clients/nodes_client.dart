// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/node.dart';

part 'nodes_client.g.dart';

@RestApi()
abstract class NodesClient {
  factory NodesClient(Dio dio, {String? baseUrl}) = _NodesClient;

  @GET('/api/v1/nodes')
  Future<Node> getNodes();
}
