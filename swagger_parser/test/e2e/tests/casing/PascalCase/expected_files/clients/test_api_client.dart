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

  @GET('/users/{UserId123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('UserId123') required String userId123,
    @Query('IsNotOnBlocklist') required bool isNotOnBlocklist,
    @Query('HttpMethod') required String httpMethod,
    @Query('ApiKey') required String apiKey,
  });

  @POST('/api/v2/Http2Protocol')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('Oauth2Token') required String oauth2Token,
    @Query('XmlData') required String xmlData,
    @Query('Html5Parser') required String html5Parser,
  });

  @PUT('/api/V1ApiEndpoint')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('Xml2jsonConverter') required String xml2jsonConverter,
    @Query('Api2V3Endpoint') required String api2V3Endpoint,
    @Query('SqlDbConnection') required String sqlDbConnection,
  });

  @DELETE('/api/HttpsConnection')
  Future<void> deleteHttpsConnection({
    @Query('XmlHttpRequest') required String xmlHttpRequest,
    @Query('JwtAuthToken') required String jwtAuthToken,
    @Query('JsonApiResponse') required String jsonApiResponse,
  });

  @GET('/api/UuidV4Generator')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('ABC') required String abc,
    @Query('XYZ') required String xyz,
    @Query('IoOperation') required String ioOperation,
    @Query('UiComponent') required String uiComponent,
    @Query('IdField') required String idField,
  });

  @POST('/api/Oauth2JwtToken')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('CssHtml5Renderer') required String cssHtml5Renderer,
    @Query('ApiV2HttpsEndpoint') required String apiV2HttpsEndpoint,
    @Query('Xml2jsonV3Parser') required String xml2jsonV3Parser,
  });
}
