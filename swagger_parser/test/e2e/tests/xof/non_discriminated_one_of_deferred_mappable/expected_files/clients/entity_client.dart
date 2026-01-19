// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/cat_dog_human.dart';

part 'entity_client.g.dart';

@RestApi()
abstract class EntityClient {
  factory EntityClient(Dio dio, {String? baseUrl}) = _EntityClient;

  /// Get an entity (returns top-level oneOf)
  @GET('/entity')
  Future<CatDogHuman> getEntity();
}
