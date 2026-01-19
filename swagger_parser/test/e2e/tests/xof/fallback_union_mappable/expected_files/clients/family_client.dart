// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/family1.dart';
import '../models/family2.dart';

part 'family_client.g.dart';

@RestApi()
abstract class FamilyClient {
  factory FamilyClient(Dio dio, {String? baseUrl}) = _FamilyClient;

  /// Get family 1 (with discriminator)
  @GET('/family1')
  Future<Family1> getFamily1();

  /// Get family 2 (without discriminator)
  @GET('/family2')
  Future<Family2> getFamily2();
}
