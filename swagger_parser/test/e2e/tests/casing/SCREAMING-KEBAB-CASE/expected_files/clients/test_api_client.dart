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

  @GET('/users/{USER-ID-123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('USER-ID-123') required String userId123,
    @Query('IS-NOT-ON-BLOCKLIST') required bool isNotOnBlocklist,
    @Query('HTTP-METHOD') required String httpMethod,
    @Query('API-KEY') required String apiKey,
  });

  @POST('/api/v2/HTTP2-PROTOCOL')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('OAUTH2-TOKEN') required String oauth2Token,
    @Query('XML-DATA') required String xmlData,
    @Query('HTML5-PARSER') required String html5Parser,
  });

  @PUT('/api/V1-API-ENDPOINT')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('XML2JSON-CONVERTER') required String xml2jsonConverter,
    @Query('API-2-V3-ENDPOINT') required String api2V3Endpoint,
    @Query('SQL-DB-CONNECTION') required String sqlDbConnection,
  });

  @DELETE('/api/HTTPS-CONNECTION')
  Future<void> deleteHttpsConnection({
    @Query('XML-HTTP-REQUEST') required String xmlHttpRequest,
    @Query('JWT-AUTH-TOKEN') required String jwtAuthToken,
    @Query('JSON-API-RESPONSE') required String jsonApiResponse,
  });

  @GET('/api/UUID-V4-GENERATOR')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('A-B-C') required String aBC,
    @Query('X-Y-Z') required String xYZ,
    @Query('IO-OPERATION') required String ioOperation,
    @Query('UI-COMPONENT') required String uiComponent,
    @Query('ID-FIELD') required String idField,
  });

  @POST('/api/OAUTH2-JWT-TOKEN')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('CSS-HTML5-RENDERER') required String cssHtml5Renderer,
    @Query('API-V2-HTTPS-ENDPOINT') required String apiV2HttpsEndpoint,
    @Query('XML2JSON-V3-PARSER') required String xml2jsonV3Parser,
  });
}
