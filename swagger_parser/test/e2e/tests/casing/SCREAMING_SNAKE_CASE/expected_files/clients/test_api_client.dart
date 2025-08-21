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

  @GET('/users/{USER_ID_123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('USER_ID_123') required String userId123,
    @Query('IS_NOT_ON_BLOCKLIST') required bool isNotOnBlocklist,
    @Query('HTTP_METHOD') required String httpMethod,
    @Query('API_KEY') required String apiKey,
  });

  @POST('/api/v2/HTTP2_PROTOCOL')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('OAUTH2_TOKEN') required String oauth2Token,
    @Query('XML_DATA') required String xmlData,
    @Query('HTML5_PARSER') required String html5Parser,
  });

  @PUT('/api/V1_API_ENDPOINT')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('XML2JSON_CONVERTER') required String xml2jsonConverter,
    @Query('API_2_V3_ENDPOINT') required String api2V3Endpoint,
    @Query('SQL_DB_CONNECTION') required String sqlDbConnection,
  });

  @DELETE('/api/HTTPS_CONNECTION')
  Future<void> deleteHttpsConnection({
    @Query('XML_HTTP_REQUEST') required String xmlHttpRequest,
    @Query('JWT_AUTH_TOKEN') required String jwtAuthToken,
    @Query('JSON_API_RESPONSE') required String jsonApiResponse,
  });

  @GET('/api/UUID_V4_GENERATOR')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('A_B_C') required String aBC,
    @Query('X_Y_Z') required String xYZ,
    @Query('IO_OPERATION') required String ioOperation,
    @Query('UI_COMPONENT') required String uiComponent,
    @Query('ID_FIELD') required String idField,
  });

  @POST('/api/OAUTH2_JWT_TOKEN')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('CSS_HTML5_RENDERER') required String cssHtml5Renderer,
    @Query('API_V2_HTTPS_ENDPOINT') required String apiV2HttpsEndpoint,
    @Query('XML2JSON_V3_PARSER') required String xml2jsonV3Parser,
  });
}
