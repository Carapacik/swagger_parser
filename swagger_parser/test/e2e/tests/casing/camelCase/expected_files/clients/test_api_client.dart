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

  @GET('/users/{userId123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('userId123') required String userId123,
    @Query('isNotOnBlocklist') required bool isNotOnBlocklist,
    @Query('httpMethod') required String httpMethod,
    @Query('apiKey') required String apiKey,
  });

  @POST('/api/v2/http2Protocol')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('oauth2Token') required String oauth2Token,
    @Query('xmlData') required String xmlData,
    @Query('html5Parser') required String html5Parser,
  });

  @PUT('/api/v1ApiEndpoint')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('xml2jsonConverter') required String xml2jsonConverter,
    @Query('api2V3Endpoint') required String api2V3Endpoint,
    @Query('sqlDbConnection') required String sqlDbConnection,
  });

  @DELETE('/api/httpsConnection')
  Future<void> deleteHttpsConnection({
    @Query('xmlHttpRequest') required String xmlHttpRequest,
    @Query('jwtAuthToken') required String jwtAuthToken,
    @Query('jsonApiResponse') required String jsonApiResponse,
  });

  @GET('/api/uuidV4Generator')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('aBC') required String aBc,
    @Query('xYZ') required String xYz,
    @Query('ioOperation') required String ioOperation,
    @Query('uiComponent') required String uiComponent,
    @Query('idField') required String idField,
  });

  @POST('/api/oauth2JwtToken')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('cssHtml5Renderer') required String cssHtml5Renderer,
    @Query('apiV2HttpsEndpoint') required String apiV2HttpsEndpoint,
    @Query('xml2jsonV3Parser') required String xml2jsonV3Parser,
  });
}
