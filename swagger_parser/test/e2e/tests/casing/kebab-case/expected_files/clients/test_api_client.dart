// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/complex_casing_model.dart';

part 'test_api_client.g.dart';

@RestApi()
abstract class TestApiClient {
  factory TestApiClient(Dio dio, {String? baseUrl}) = _TestApiClient;

  @GET('/users/{user-id-123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('user-id-123') required String userId123,
    @Query('is-not-on-blocklist') required bool isNotOnBlocklist,
    @Query('http-method') required String httpMethod,
    @Query('api-key') required String apiKey,
  });

  @POST('/api/v2/http2-protocol')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('oauth2-token') required String oauth2Token,
    @Query('xml-data') required String xmlData,
    @Query('html5-parser') required String html5Parser,
  });

  @PUT('/api/v1-api-endpoint')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('xml2json-converter') required String xml2jsonConverter,
    @Query('api-2-v3-endpoint') required String api2V3Endpoint,
    @Query('sql-db-connection') required String sqlDbConnection,
  });

  @DELETE('/api/https-connection')
  Future<void> deleteHttpsConnection({
    @Query('xml-http-request') required String xmlHttpRequest,
    @Query('jwt-auth-token') required String jwtAuthToken,
    @Query('json-api-response') required String jsonApiResponse,
  });

  @GET('/api/uuid-v4-generator')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('a-b-c') required String aBC,
    @Query('x-y-z') required String xYZ,
    @Query('io-operation') required String ioOperation,
    @Query('ui-component') required String uiComponent,
    @Query('id-field') required String idField,
  });

  @POST('/api/oauth2-jwt-token')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('css-html5-renderer') required String cssHtml5Renderer,
    @Query('api-v2-https-endpoint') required String apiV2HttpsEndpoint,
    @Query('xml2json-v3-parser') required String xml2jsonV3Parser,
  });
}
