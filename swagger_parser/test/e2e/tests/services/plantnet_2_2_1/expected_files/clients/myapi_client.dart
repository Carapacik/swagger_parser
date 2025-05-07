// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/identification_result.dart';
import '../models/lang.dart';
import '../models/languages_list.dart';
import '../models/model1.dart';
import '../models/model3.dart';
import '../models/model6.dart';
import '../models/model8.dart';
import '../models/organs.dart';
import '../models/project.dart';
import '../models/projects_list.dart';
import '../models/species.dart';
import '../models/species_list.dart';
import '../models/type.dart';

part 'myapi_client.g.dart';

@RestApi()
abstract class MyapiClient {
  factory MyapiClient(Dio dio, {String? baseUrl}) = _MyapiClient;

  /// Check API health.
  ///
  /// Returns current health status of My Pl@ntNet API and inrastructure.
  @GET('/v2/_status')
  Future<Model1> getV2Status();

  /// Languages service.
  ///
  /// Get the list of available languages (ISO 639-1).
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/languages')
  Future<LanguagesList> getV2Languages({
    @Query('api-key') String? apiKey,
  });

  /// Projects service.
  ///
  /// Get the list of projects that can be used for identification.
  ///
  /// [lang] - i18n (default: en).
  ///
  /// [lat] - Latitude (WGS 84 decimal degrees): filter and sort projects according to geolocation.
  ///
  /// [lon] - Longitude (WGS 84 decimal degrees): filter and sort projects according to geolocation.
  ///
  /// [type] - Projects type.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/projects')
  Future<ProjectsList> getV2Projects({
    @Query('lat') num? lat,
    @Query('lon') num? lon,
    @Query('api-key') String? apiKey,
    @Query('lang') Lang lang = Lang.en,
    @Query('type') Type type = Type.kt,
  });

  /// Species service.
  ///
  /// Get the list of species that can be identified.
  ///
  /// [lang] - i18n (default: en).
  ///
  /// [type] - Projects type.
  ///
  /// [pageSize] - Number of results per page. Must be used along with "page". Set to null to disable pagination.
  ///
  /// [page] - Page number starting at 1. Must be used along with "pageSize". Set to null to disable pagination.
  ///
  /// [prefix] - Return only species starting with given prefix.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/species')
  Future<SpeciesList> getV2Species({
    @Query('pageSize') int? pageSize,
    @Query('page') int? page,
    @Query('prefix') String? prefix,
    @Query('api-key') String? apiKey,
    @Query('lang') Lang lang = Lang.en,
    @Query('type') Type type = Type.kt,
  });

  /// Check subscription status and details.
  ///
  /// Returns status, details and statistics for your account.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/subscription')
  Future<Model3> getV2Subscription({
    @Query('api-key') String? apiKey,
  });

  /// Identification service.
  ///
  /// This service allows plant identification (one request => one plant).
  ///
  /// [project] - Referential in which to search the plant (use one of the available projects or "all" to get the results of the most relevant project).
  ///
  /// [images] - Images URLs (all images must respresent the same plant) [max: 5 images].
  ///
  /// [organs] - Organs associated to images (must contains one of: leaf, flower, fruit, bark, auto. Could contains: habit, other) [max 5 organs and organs.length must be equal to images.length].
  ///
  /// [includeRelatedImages] - If true, for each probable species, the most similar images will be returned.
  ///
  /// [noReject] - Disables "no result" in case of reject class match.
  ///
  /// [nbResults] - Max. number of species in identification results − a higher number increases response time.
  ///
  /// [lang] - i18n (default: en).
  ///
  /// [type] - Model type: use "kt" for new POWO / WGSRPD based floras and identification engine (2023+), "legacy" for legacy floras and identification engine (2022).
  ///
  /// [apiKey] - Your private API key.
  ///
  /// [authenixAccessToken] - Authenix access token − Authenix is an alternative way of authenticating. Use api-key unless you know what this is.
  @GET('/v2/identify/{project}')
  Future<IdentificationResult> getV2IdentifyProject({
    @Query('images') required List<String> images,
    @Query('include-related-images') bool includeRelatedImages = false,
    @Query('no-reject') bool noReject = false,
    @Query('nb-results') int nbResults = 10,
    @Query('lang') Lang lang = Lang.en,
    @Query('organs') List<Organs>? organs,
    @Query('type') Type? type,
    @Query('api-key') String? apiKey,
    @Query('authenix-access-token') String? authenixAccessToken,
    @Path('project') String project = 'all',
  });

  /// Identification service.
  ///
  /// This service allows plant identification (one request => one plant)<br>Mime: image/jpeg or image/png<br>Max POST size: 52428800 bytes.
  ///
  /// [project] - Referential in which to search the plant (use one of the available projects or "all" to get the results of the most relevant project).
  ///
  /// [includeRelatedImages] - If true, for each probable species, the most similar images will be returned.
  ///
  /// [noReject] - Disables "no result" in case of reject class match.
  ///
  /// [nbResults] - Max. number of species in identification results − a higher number increases response time.
  ///
  /// [lang] - i18n (default: en).
  ///
  /// [type] - Model type: use "kt" for new POWO / WGSRPD based floras and identification engine (2023+), "legacy" for legacy floras and identification engine (2022).
  ///
  /// [apiKey] - Your private API key.
  ///
  /// [authenixAccessToken] - Authenix access token − Authenix is an alternative way of authenticating. Use api-key unless you know what this is.
  ///
  /// [images] - Images (all images must respresent the same plant) [max: 5 images].
  ///
  /// [organs] - Organs associated to images (must contains one of: leaf, flower, fruit, bark, auto. Could contains: habit, other) [max 5 organs and organs.length must be equal to images.length].
  @MultiPart()
  @POST('/v2/identify/{project}')
  Future<IdentificationResult> postV2IdentifyProject({
    @Part(name: 'images') required List<File> images,
    @Query('type') Type? type,
    @Query('api-key') String? apiKey,
    @Query('authenix-access-token') String? authenixAccessToken,
    @Part(name: 'organs') List<Organs>? organs,
    @Query('include-related-images') bool includeRelatedImages = false,
    @Query('no-reject') bool noReject = false,
    @Query('nb-results') int nbResults = 10,
    @Query('lang') Lang lang = Lang.en,
    @Path('project') String project = 'all',
  });

  /// Check quota consumption.
  ///
  /// Returns number of requests and remaining quota for your account, for the given day.
  ///
  /// [day] - Day in the format YYYY-MM-DD.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/quota/daily')
  Future<Model6> getV2QuotaDaily({
    @Query('api-key') String? apiKey,
    @Query('day') String day = '2025-05-03',
  });

  /// Check quota consumption history.
  ///
  /// Returns number of requests by day for your account, for the given year.
  ///
  /// [year] - Year in the format YYYY.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/quota/history')
  Future<Model8> getV2QuotaHistory({
    @Query('api-key') String? apiKey,
    @Query('year') String year = '2025',
  });

  /// Species by project service.
  ///
  /// Get the list of species that can be identified in a given project.
  ///
  /// [project] - Project to extract available species from.
  ///
  /// [lang] - i18n (default: en).
  ///
  /// [pageSize] - Number of results per page. Must be used along with "page". Set to null to disable pagination.
  ///
  /// [page] - Page number starting at 1. Must be used along with "pageSize". Set to null to disable pagination.
  ///
  /// [prefix] - Return only species starting with given prefix.
  ///
  /// [apiKey] - Your private API key.
  @GET('/v2/projects/{project}/species')
  Future<SpeciesList> getV2ProjectsProjectSpecies({
    @Query('pageSize') int? pageSize,
    @Query('page') int? page,
    @Query('prefix') String? prefix,
    @Query('api-key') String? apiKey,
    @Query('lang') Lang lang = Lang.en,
    @Path('project') String project = 'k-southwestern-europe',
  });
}
