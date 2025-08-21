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

  @GET('/users/{user_id_123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('user_id_123') required String userId123,
    @Query('is_not_on_blocklist') required bool isNotOnBlocklist,
    @Query('http_method') required String httpMethod,
    @Query('api_key') required String apiKey,
  });

  @POST('/api/v2/http2_protocol')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('oauth2_token') required String oauth2Token,
    @Query('xml_data') required String xmlData,
    @Query('html5_parser') required String html5Parser,
  });

  @PUT('/api/v1_api_endpoint')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('xml2json_converter') required String xml2jsonConverter,
    @Query('api_2_v3_endpoint') required String api2V3Endpoint,
    @Query('sql_db_connection') required String sqlDbConnection,
  });

  @DELETE('/api/https_connection')
  Future<void> deleteHttpsConnection({
    @Query('xml_http_request') required String xmlHttpRequest,
    @Query('jwt_auth_token') required String jwtAuthToken,
    @Query('json_api_response') required String jsonApiResponse,
  });

  @GET('/api/uuid_v4_generator')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('a_b_c') required String aBC,
    @Query('x_y_z') required String xYZ,
    @Query('io_operation') required String ioOperation,
    @Query('ui_component') required String uiComponent,
    @Query('id_field') required String idField,
  });

  @POST('/api/oauth2_jwt_token')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('css_html5_renderer') required String cssHtml5Renderer,
    @Query('api_v2_https_endpoint') required String apiV2HttpsEndpoint,
    @Query('xml2json_v3_parser') required String xml2jsonV3Parser,
  });
}
