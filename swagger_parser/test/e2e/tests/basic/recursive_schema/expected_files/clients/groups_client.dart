// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/acme_group_list.dart';

part 'groups_client.g.dart';

@RestApi()
abstract class GroupsClient {
  factory GroupsClient(Dio dio, {String? baseUrl}) = _GroupsClient;

  @GET('/api/v1/groups')
  Future<AcmeGroupList> getGroups();
}
