// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/family.dart';
import '../models/get_family_members_response_union.dart';

part 'family_client.g.dart';

@RestApi()
abstract class FamilyClient {
  factory FamilyClient(Dio dio, {String? baseUrl}) = _FamilyClient;

  /// Get a family
  @GET('/family')
  Future<Family> getFamily();

  /// Get family members (returns oneOf directly)
  @GET('/family/members')
  Future<List<GetFamilyMembersResponseUnion>> getFamilyMembers();
}
