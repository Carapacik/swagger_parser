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

  @GET('/users/{User-Id-123}')
  Future<ComplexCasingModel> getUserById123({
    @Path('User-Id-123') required String userId123,
    @Query('Is-Not-On-Blocklist') required bool isNotOnBlocklist,
    @Query('Http-Method') required String httpMethod,
    @Query('Api-Key') required String apiKey,
  });

  @POST('/api/v2/Http2-Protocol')
  Future<ComplexCasingModel> postHttp2Protocol({
    @Query('Oauth2-Token') required String oauth2Token,
    @Query('Xml-Data') required String xmlData,
    @Query('Html5-Parser') required String html5Parser,
  });

  @PUT('/api/V1-Api-Endpoint')
  Future<ComplexCasingModel> updateV1ApiEndpoint({
    @Query('Xml2json-Converter') required String xml2jsonConverter,
    @Query('Api-2-V3-Endpoint') required String api2V3Endpoint,
    @Query('Sql-Db-Connection') required String sqlDbConnection,
  });

  @DELETE('/api/Https-Connection')
  Future<void> deleteHttpsConnection({
    @Query('Xml-Http-Request') required String xmlHttpRequest,
    @Query('Jwt-Auth-Token') required String jwtAuthToken,
    @Query('Json-Api-Response') required String jsonApiResponse,
  });

  @GET('/api/Uuid-V4-Generator')
  Future<ComplexCasingModel> getUuidV4Generator({
    @Query('A-B-C') required String aBC,
    @Query('X-Y-Z') required String xYZ,
    @Query('Io-Operation') required String ioOperation,
    @Query('Ui-Component') required String uiComponent,
    @Query('Id-Field') required String idField,
  });

  @POST('/api/Oauth2-Jwt-Token')
  Future<ComplexCasingModel> postOauth2JwtToken({
    @Query('Css-Html5-Renderer') required String cssHtml5Renderer,
    @Query('Api-V2-Https-Endpoint') required String apiV2HttpsEndpoint,
    @Query('Xml2json-V3-Parser') required String xml2jsonV3Parser,
  });
}
